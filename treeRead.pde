// contains:
// Tree TreeReadFlatfile

Tree TreeReadFlatfile(String filename) {
  Tree t;
  
  // Load file as array of strings. First line is data labels.
  String[] lines = loadStrings(filename);
  String[] data_labels = split(lines[0], ' ');
    
  // Initialize columns
  int ID_column = -1, parent_column = -1, name_column = -1, distance_column = -1;    
  for (int i = 0; i < data_labels.length; i++) {
    if (match(data_labels[i],"parent") != null) {
      parent_column = i;
    } else if (match(data_labels[i],"ID") != null) {
      ID_column = i;
    } else if (match(data_labels[i],"name") != null) {
      name_column = i;
    } else if (match(data_labels[i],"distance") != null) {
      distance_column = i;
    }
  }

  // Abort if no columns read "parent" and "ID"
  if (ID_column == -1 || parent_column == -1) {
    println ("ERROR: no labeled parent and ID columns in first line! Check format requirements.");
    exit();
  }
    
  // Read in root, check that it satisfies "parent and self ID are same" condition
  String[] root_data = split(lines[1], ' ');
  if (parseInt(root_data[parent_column]) != parseInt(root_data[ID_column])) {
    println ("ERROR: First line should be root node: parent " + root_data[ID_column] 
      + " and ID " + root_data[parent_column] + " columns should be the same for first node (root)!");
    exit();
  }
  int curr_ID = parseInt(root_data[ID_column]);
  int curr_parent = parseInt(root_data[parent_column]);
  String curr_name = "";      // default since we can't assume it exists
  float curr_distance = 1.0;  // default since we can't assume it exists
  if (name_column >= 0) { curr_name = root_data[name_column]; }
  if (distance_column >= 0) { curr_distance = parseFloat(root_data[distance_column]); }
    
  // Add root to the tree
  TreeNode root = new TreeNode(curr_ID, curr_parent, curr_name, curr_distance);
  t = new Tree(root);
    
  // Now go through all the nodes and add to the tree...
  for (int i = 1; i < lines.length; i++) {
    String[] node_data = split(lines[i], ' ');
    curr_ID = parseInt(node_data[ID_column]);
    curr_parent = parseInt(node_data[parent_column]);
    if (name_column >= 0) { curr_name = node_data[name_column]; }
    if (distance_column >= 0) { curr_distance = parseFloat(node_data[distance_column]); }
    TreeNode currNode = new TreeNode(curr_ID, curr_parent, curr_name, curr_distance);
    t.addNode(currNode);
    //println(i + " " + node_data[2] + " next...");
  }
  
  return t;
}

Tree TreeReadNewick(String filename) {
  Tree t;
  
  TreeNode this_node = new TreeNode(0, 0, "Root", 1);
  t = new Tree(this_node);
  
  String[] lines = loadStrings(filename);
  int curr_node_ID = this_node.node_ID;
  int largest_node_ID = curr_node_ID;
  int[] path_to_root = { curr_node_ID };
  char[] curr_name = new char[0];
  char[] curr_name_buffer = new char[0];
  char[] curr_dist = new char[0];
  int curr_node_parent;
  boolean hit_colon = false;
  boolean in_brackets = false;
  
  for (int i = 0; i < lines.length; i++ ) {
    char[] characters = lines[i].toCharArray();
    for (int j = 0; j < characters.length; j++) {
      switch(characters[j]) {
        case ' ':
          // Ignore spaces unless they're occurring inside names
          if (curr_name.length > 0 && hit_colon == false) {
            curr_name_buffer = (char[]) append(curr_name, characters[j]);
          }
          break;
        case '\t':
          // Ignore tabs
          break;
        case '(':
          // move current node to parent, make new node
          curr_node_parent = curr_node_ID;
          largest_node_ID++; curr_node_ID = largest_node_ID;
          //println("TreeReadNewick: Open paren: moving " + curr_node_parent + " to parent, current node is now " + curr_node_ID);
          path_to_root = (int[]) append(path_to_root, curr_node_parent);
          // clear old variables
          curr_name = new char[0]; curr_name_buffer = new char[0];
          curr_dist = new char[0];
          hit_colon = false;
          // store new node
          this_node = new TreeNode(curr_node_ID, curr_node_parent, "", 1.0);
          //println("TreeReadNewick: Add node...");
          t.addNode(this_node);
          break;
        case ',':
          //println("TreeReadNewick: Comma: fixing " + curr_node_ID + " to have name " + new String(curr_name));
          // record name and distance, if any
          if (curr_name.length > 0) {
            t.getNode(curr_node_ID).node_name = new String(curr_name);
            curr_name = new char[0]; curr_name_buffer = new char[0];
          }
          if (curr_dist.length > 0) {
            t.getNode(curr_node_ID).distance = parseFloat(new String(curr_dist));
            curr_dist = new char[0];
          }
          // clear old variables
          hit_colon = false;
          // set parent and create new node
          curr_node_parent = path_to_root[path_to_root.length - 1];
          largest_node_ID++;
          curr_node_ID = largest_node_ID;
          //println("TreeReadNewick:   ...parent remains " + curr_node_parent + " and current node is now " + curr_node_ID);
          this_node = new TreeNode(curr_node_ID, curr_node_parent, "", 1.0);
          t.addNode(this_node);
          break;
        case ')':
          //println("TreeReadNewick: Close paren: fixing " + curr_node_ID + " to have name " + new String(curr_name));
          //record name and distance, if any
          if (curr_name.length > 0) {
            t.getNode(curr_node_ID).node_name = new String(curr_name);
            curr_name = new char[0]; curr_name_buffer = new char[0];
          }
          if (curr_dist. length > 0) {
            t.getNode(curr_node_ID).distance = parseFloat(new String(curr_dist));
            curr_dist = new char[0];
          }
          // clear old variables
          hit_colon = false;
          // reset parent, back up on path_to_root
          curr_node_ID = path_to_root[path_to_root.length - 1];
          int[] new_path = new int[0];
          for (int k = 0; k < (path_to_root.length - 1); k++) {
            new_path = (int[]) append(new_path, path_to_root[k]);
          }
          path_to_root = new_path;
          curr_node_parent = path_to_root[path_to_root.length - 1];
          //println("TreeReadNewick:    ...parent is now " + curr_node_parent + " and current node is back to " + curr_node_ID);
          break;
        case '[': 
          in_brackets = true;
          break;
        case ']':
          in_brackets = false;
          break;
        case ':':
          hit_colon = true;
          break;
        case ';':
          //println("TreeReadNewick: Semicolon encountered... this should be the end");
          if (curr_name.length > 0) {
            t.getNode(curr_node_ID).node_name = new String(curr_name);
            curr_name = new char[0]; curr_name_buffer = new char[0];
          }
          if (curr_dist.length > 0) {
            t.getNode(curr_node_ID).distance = parseFloat(new String(curr_dist));
            curr_dist = new char[0];
          }
          break;
        default:
          if (hit_colon == true) {
            if (in_brackets == false) {
              curr_dist = (char[]) append(curr_dist, characters[j]);
            }
          } else {
            for (int k=0; k<curr_name_buffer.length; k++) {
              curr_name = (char[]) append(curr_name, curr_name_buffer[k]);
            }
            curr_name_buffer = new char[0];
            curr_name = (char[]) append(curr_name, characters[j]);
          } 
          break;
      }
    }
  }
  

  return t;
}


