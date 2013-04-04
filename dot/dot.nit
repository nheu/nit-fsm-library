module dot

class DotGraph
	var extension: String  = ".dot"
	var graph_id: String
	var is_directed: Bool
	var graph_attrs =  "graph [fontsize=10]"
	# graph [ bgcolor=lightgray, resolution=128, fontname=Arial, fontcolor=blue, fontsize=12 ]
	var node_stmt_list = new List[DotNode]
	var edge_stmt_list = new List[DotEdge]
	var _color: nullable String

	#Initialisateur prenant en argument le nom du graphe
	#Par défaut la fonction d'export créera un fichier
	#portant le nom du graphe.
	init(name: String) do
		self.is_directed = false
		self.graph_id = name
	end

	#comment
	init directed(name: String) do
		self.is_directed = true
		self.graph_id = name
	end

	fun graph_type: String do
		if is_directed then return "digraph"
		return "graph"
	end

	fun color=(color: String) do _color = color	

	fun color: nullable String do return _color

	#comment
	fun export do
		var buf = new Buffer
		buf.append(graph_type + " " + graph_id + " \{")
		#GRAPH ATTRIBUTES
		buf.append("\n\t" + graph_attrs)
		#NODES STATEMENTS
		for node_stmt in node_stmt_list do
			if color != null and node_stmt.color == null then node_stmt.color = color.as(not null)
			buf.append("\n\t" + node_stmt.to_s)
		end
		#EDGES STATEMENTS
		for edge_stmt in edge_stmt_list do
			if color != null and edge_stmt.color == null then edge_stmt.color = color.as(not null)
			buf.append("\n\t" + edge_stmt.to_s)
		end
		buf.append("\n" + "}")

	    save(open(graph_id + extension), buf)
	end

	fun add_node(node: DotNode) do
		node_stmt_list.add(node)
	end

	#comment
	fun add_node_state(node_id: String, is_initial: Bool, is_final: Bool) do
		node_stmt_list.add(new DotNodeState.state(node_id, is_initial, is_final))
	end

	#comment
	fun add_edge(source: String, target: String, lbl: nullable String) do
		var edge : DotEdge
		if is_directed then
			edge = new DotArrow.with_label(source, target, lbl)
		else edge = new DotEdge.with_label(source, target, lbl)
		edge_stmt_list.add(edge)
	end

	#Ouvre un flot vers le fichier renseigné
	#Si non existant, celui-ci est autmatiquement crée.
	fun open(path: String): OFStream do
		return new OFStream.open(path)
	end

	#Sauvegarde le tampon dans le flot spécifié.
	fun save(stream: OFStream, buffer: Buffer) do
		stream.write(buffer.to_s)
	end
end

#Représente un noeud du graphe
class DotNode
	var sBOX: String = "box"
	var sPOLLYGON: String = "polygon"
	var sELLIPSE: String = "ellipse"
	var sOVAL: String = "oval"
	var sCIRCLE: String = "circle"
	var sPOINT: String = "point"
	var sEGG: String = "egg"
	var sTRIANGLE: String = "triangle"
	var sTEXT: String = "plaintext"
	var sDIAMOND: String = "diamond"
	var sTRAPEZE: String = "trapezium"
	var sPARALLELOGRAM: String = "parallelogram"
	var sHOUSE: String = "house"
	var sPENTAGON: String = "pentagon"
	var sHEXAGON: String = "hexagon"
	var sSEPTAGON: String = "septagon"
	var sOCTAGON: String = "octagon"
	var sDOUBLECIRCLE: String = "doublecircle"
	var sDOUBLEOCTAGON: String = "doubleoctagon"

	var _id: String
	var lbl: nullable String
	var shape: nullable String
	var _color: nullable String

	init(id: String) do
		with_shape(id, sELLIPSE)
	end

	init with_shape(id: String, shape: String) do
		self._id = id
		self.shape = shape
		self.lbl = _id
	end

	fun id: String do return _id

	fun color=(color: String) do _color = color

	fun color: nullable String do return _color

	fun has_param: Bool do
		if lbl != null or shape != null or _color != null then return true
		return false
	end 
	
	#comment
	redef fun to_s do
		if lbl == null and shape == null then return _id
		var buf = new Buffer
		buf.append("node ")
		if has_param then		
			buf.append("[")
			if lbl != null then
				buf.append(" shape=" + shape.as(not null))
			end
			if shape != null then
				buf.append(" label=\"" + lbl.as(not null) + "\"")
			end			
			if _color != null then	
				buf.append(" color=" + _color.as(not null))		
			else print "PAS GLOP"
			
			buf.append(" ]")
		end
		buf.append(_id + ";")
		return buf.to_s
	end
end

#Spécialise un noeud de graphe
#Représente un état d'automate
class DotNodeState
	super DotNode
	var initial = false
	var final = false

	init state(id: String, initial: Bool, final: Bool) do
		init(id)
		self.lbl = lbl
		self.initial = initial
		self.final = final
		if final then
			self.shape = sDOUBLECIRCLE
		else self.shape = sCIRCLE
	end

	fun is_initial: Bool do return initial

	fun create_entry_stub(stub_id: String, dot_graph: DotGraph) do
		dot_graph.add_node(new DotNode.with_shape(id, sPOINT))
		dot_graph.add_edge(id, self._id, id)
	end
end

#Représente une arête du graphe
class DotEdge
	var source: String
	var target: String
	var lbl: nullable String
	#var style: c
	var _color: nullable String

	#Initialisateur d'une arête
	#param source : nom du noeud source
	#param target : nom du noeud destination
	init(source: String, target: String) do
		self.source = source
		self.target = target
	end

	#Initialisateur d'une arête nommée
	init with_label(source: String, target: String, lbl: nullable String) do
		init(source, target)
		self.lbl = lbl
	end

	fun has_param: Bool do 
		if lbl != null or _color != null then return true
		return false	
	end

	fun color=(color: String) do _color = color	

	fun color: nullable String do return _color

	#Retourne le séparateur de noeud utilisé par ce type d'arête
	fun node_separator: String do return "--"

	#Retourne le litéral correspondant à cet arête
	redef fun to_s do
		var buf = new Buffer
		buf.append(source + node_separator + target)
		if has_param then
			buf.append(" [")
			if lbl != null then
				buf.append(" label=\"" + lbl.as(not null) + "\"")			
			end
			if _color != null then
				buf.append(" color=" + _color.as(not null))			
			end
			buf.append(" ]")	
		end
		buf.append(";")
		return buf.to_s
	end
end

#Spécialise une arête de graphe
#Représente un arc
class DotArrow
	super DotEdge

	init with_label(source: String, target: String, lbl: nullable String) do

	end

	#Retourne le séparateur de noeud utilisé par ce type d'arête
	redef fun node_separator: String do return "->"
end



