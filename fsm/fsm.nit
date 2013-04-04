module fsm
import out
import dot

#Alphabet - ensemble des symboles reconnus par un automate
#Actuellement un alphabet n'est rien d'autre qu'un ensemble de symboles du même type
class Alphabet[E]
	super List[E]
	init do end
end

#Helper permettant de créer un automate respectant la définition de base
# -composé d'un ensemble d'états
# -un seul état initial
# -un ou plusieurs états acceptants/finaux
# -une transition relie toujours deux états
# -un DFA(automate fini déterministe) : un symbole associée à une seule transition
# -un NFA(automate fini non-déterministe) : un symbole associée peut-être lié à plusieurs transition
class FsmBuilder[E]
	#alphabet accepté par l'automate
	var current_alphabet : nullable Alphabet[E]
	#état initial (unique) de l'automate
	var initial_state : nullable FsmState
	#ensemble des états finaux acceptés
	var final_states = new HashSet[FsmState]
	#key == state id, value == associated state object
	var states = new HashMap[Object, nullable FsmState]
	#key == incomplete transition, value == target state id,
	var pending_transitions = new HashMap[Internal_Transition, Object]
	var validated_transitions = new HashSet[FsmTransition]
	var mode = 0
	var constructed = false

	#Log
	var out = new Out

	#Initialisateur
	init(alphabet : Alphabet[E]) do
		print "Construction de l'automate - début"
		print "--------------------------------------"
		current_alphabet = alphabet
	end

	#Active le mode verbeux du constructeur d'automate - chaque étape est imprimée sur la console
	fun trace(active: Bool) do out.is_activated = true

	#Permet de définir le vocabulaire/alphabet sur lequel travail l'automate
	#fun define_alphabet(alphabet : Sequence[Object]) do current_alphabet = alphabet

	#Permet d'obtenir un helper pour construire un état
	fun get_state_builder(state_id: Object) : nullable State_Builder[E] do
		if constructed or states.has_key(state_id) then return null
		states[state_id] = null
		out.log("FsmBuilder", "Demande d'un State_Builder pour l'état d'id : " + state_id.to_s)
		return new State_Builder[E].verbose(self, state_id, out.is_activated)
	end

	#Ajout d'un état à l'automate
	fun add_state(state: FsmState) do
		if constructed == false then
			states[state.id] = state
			out.log("FsmBuilder", "Etat " + state.id.to_s + " ajouté à l'automate")
		end
	end

	#Définition de l'état initial
	fun set_initial(state: FsmState) do
		if constructed == false then
			initial_state = state
			out.log("FsmBuilder", "Etat " + state.id.to_s + " défini comme initial")
		end
	end

	#Ajout d'un état final à l'automate
	fun add_final(state: FsmState) do
		if constructed == false then
			final_states.add(state)
			out.log("FsmBuilder", "Etat " + state.id.to_s + " défini comme final")
		end
	end

	#Première étape de la validation d'une transition
	fun add_pending_transitions(builder: State_Builder[E], transitions: HashMap[Internal_Transition, Object]) : Bool do
		if constructed or builder.is_commited then return false
		out.log("FsmBuilder", "Etat " + builder.id.to_s + " : validation des transitions du côté de l'état source")
		for key, item in transitions do
			pending_transitions[key] = item
		end
		return true
	end

	#Supprime un état n'ayant pas encore été validé
	#Note : si un état est supprimé alors toutes les transitions pour
	#lesquelles cet état est la destination seront également suppriméess
	fun rollback_pending_state(state_id: Object) do
		if constructed == false then
			states[state_id] = null
			out.log("FsmBuilder", "Etat " + state_id.to_s + " retiré de l'automate")
		end

	end

	#Retourne un objet permettant d'exécuter l'automate
	fun build : nullable FsmExecutor[E] do
		if constructed then return null
		#impossible de construire un automate sans état initial
		if initial_state == null then return null

		#On complète chaque transition avec l'objet état correspondant
		for key, item in pending_transitions do
			if states.has_key(item) and states[item] != null then
				var full_transition = new FsmTransition(key.get_label, key.get_source)
				full_transition.set_target(states[item].as(not null))
				validated_transitions.add(full_transition)
			end
		end

		#On ajoute chacune des transitions à leur état source
		for trans in validated_transitions do
			out.log("FsmBuilder", "Etat " + trans.get_source.id.to_s + " : transition vers l'état " + trans.get_target.id.to_s + " validée pour le symbole " + trans.get_label.to_s)
			trans.get_source.add_transition(trans)
		end

		print "\nBilan :"
		print "-Etats : " + states.length.to_s
		print "-Etats finaux : " + final_states.length.to_s
		print "-Transitions en attente : " + pending_transitions.length.to_s
		print "-Transitions validées : " + validated_transitions.length.to_s

		print "--------------------------------------"
		print "Construction de l'automate - fin \n"

		constructed = true
		return new FsmExecutor[E](initial_state.as(not null),
						final_states, states,
						validated_transitions)
	end

	#Sum operation
	#C = A + B :
	#Création d'un automate C en ajoutant un état initial possédant deux transitions :
	#-une transition étiquetée epsilon entre le nouvel état initial et l'état initial de l'automate A
	#-une transition étiquetée epsilon entre le nouvel état initial et l'état initial de l'automate B
	fun union(operand_builder: FsmBuilder[E]) do end

	#Product operation
	#C = AB : ajout d'une transition étiquetée epsilon entre un des état finaux de l'automate A
	#et l'état initial de l'automate B
	fun concat(operand_builder: FsmBuilder[E]) do end
end

#Helper permettant de créer un état de manière "transactionnelle"
class State_Builder[E]
	var builder : FsmBuilder[E]
	var state : FsmState
	var enter_action : nullable FsmAction
	var exit_action : nullable FsmAction
	var final = false
	var initial = false
	var commited = false
	#key == incomplete transition, value == target state id
	var pending_transitions = new HashMap[Internal_Transition, Object]

	#Log
	var out = new Out

	#Initialisateur
	#param1 : builder parent auquel notifier le commit de l'état à la fin
	#param2 : identifiant de l'état à créer
	#param3 : log
	init verbose(builder: FsmBuilder[E], state_id: Object, is_verbose: Bool) do
		out.is_activated = is_verbose
		init(builder, state_id)
	end

	#Initialisateur
	#param1 : builder parent auquel notifier le commit de l'état à la fin
	#param2 : identifiant de l'état à créer
	init(builder: FsmBuilder[E], state_id: Object) do
		self.builder = builder
		self.state = new FsmState(state_id)
	end

	#Retourne l'identifiant de l'état en cours de construction
	fun id: Object do return state.id

	#Les modifications apportées à un état ayant déjà été modifié ne seront plus prises en compte
	fun is_commited: Bool do
		return commited
	end

	#Définit une transition pour une étiquette donnée
	fun set_transition(tag: Object, target_id: Object): State_Builder[E] do
		if commited == false then
			var key = new Internal_Transition(tag, state)
			pending_transitions[key] = target_id
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : ajout transition vers l'état " + target_id.to_s + " pour le symbole " + tag.to_s)
		end
		return self
	end

	#Définit une transition par défaut
	#Identifiant de l'état destination - id car objet possiblement non existant à ce moment
	fun set_default_transition(target_id: Object): State_Builder[E] do
		if commited == false then
			var key = new Internal_Transition("*", state)
			pending_transitions[key] = target_id
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : ajout transition par défaut (*) affectée vers l'état " + target_id.to_s)
		end
		return self
	end

	#Ajout de l'action qui sera déclenchée à l'entrée dans l'état
	fun on_enter(action : FsmAction): State_Builder[E] do
		if commited == false then
			state.set_enter(action)
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : ajout d'une action lors de l'entrée dans l'état")
		end
		return self
	end

	#Ajout de l'action qui sera déclenchée à la sortie dans l'état
	fun on_exit(action : FsmAction): State_Builder[E] do
		if commited == false then
			state.set_exit(action)
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : ajout d'une action lors de la sortie de l'état")
		end
		return self
	end

	#Permet de définir cet état comme l'état initial de l'automate
	#Attention : un automate ne doit avoir qu'un état initial
	fun set_initial(is_initial : Bool): State_Builder[E] do
		if commited == false then
			initial = is_initial
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : défini comme initial")
		end
		return self
	end

	#Permet de définir cet état comme final/acceptant
	fun set_final(is_final : Bool): State_Builder[E] do
		if commited == false then
			final = is_final
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : défini comme final")
		end
		return self
	end

	#Validation de l'état
	fun commit : Bool do
		if commited == false then
			out.log(" *State_Builder", "Etat " + state.id.to_s + " : validé")
			builder.add_state(state)
			if initial then builder.set_initial(state)
			if final then builder.add_final(state)
			builder.add_pending_transitions(self, pending_transitions)
			commited = true
			return true
		end
		return false
	end

	#Annule la création de l'état
	#Impossible d'annuler un état déjà validé
	fun rollback : Bool do
		if commited then return false
		out.log(" *State_Builder", "Etat " + state.id.to_s + " : annulé")
		builder.rollback_pending_state(state.id)
		return true
	end
end

#Utilisé pour indiquer le statut dynamique d'un automate
#Valeurs possiles : started, paused, stopped
class FsmStatus
	var started = false
	var paused = false
	var stopped = false

	#Initialisateur prennant un entier pour initialiser le flag de statut
	init(stat: Int) do
		change(stat)
	end

	#Modifie le flag du statut
	fun change(stat: Int): FsmStatus do
		started = false
		paused = false
		stopped = false
		if stat == 1 then started = true
		if stat == 2 then paused = true
		if stat == 3 then stopped = true
		return self
	end
	#Retourne vrai si l'automate est en cours d'exécution
	fun is_started: Bool do return started

	#Retourne vrai si l'automate est en pause
	#Note: il est possible de reprendre l'exécution d'un automate en pause
	fun is_paused: Bool do return paused

	#Retourne vrai si l'automate est stoppé
	#Note: il est impossible de reprendre l'exécution d'un automate arrêté
	fun is_stopped: Bool do return stopped
end

abstract class AbstractAutomaton[E]
	type AlphabetType: Object
	var status_STARTED = 1
	var status_PAUSED = 2
	var status_STOPPED = 3

	#outch
	fun is_acceptable(symbol: Object): Bool do
		return symbol isa AlphabetType
	end

	#Log
	var out = new Out

	fun get_states: HashMap[Object, nullable FsmState] is abstract

	fun get_transitions: HashSet[FsmTransition] is abstract

	fun get_final_states: Set[FsmState] is abstract

	#Lancement de l'automate
	fun start: FsmStatus do
		if current_status.is_paused then
			print "Impossible de démarrer un automate en pause"
			print "Solutions possibles : poursuite (resume), reinitialisation (reset)"
			return current_status
		end
		if current_status.is_started then
			print "L'automate est déjà en cours d'excution"
			return current_status
		end
		#réinitialisation de l'automate
		reset
		print "Lancement de l'automate"
		print "--------------------------------------"
		current_state.enter
		out.log("FsmExecutor", "Demarré dans l'état : " + current_state.id.to_s)
		return status_changed(status_STARTED)
	end

	#Reprise de l'exécution de l'automate
	fun resume: FsmStatus do
		out.log("FsmExecutor", "Reprise dans l'état : " + current_state.id.to_s)
		return status_changed(status_STARTED)
	end

	#Mise en pause l'automate
	fun pause: FsmStatus do
		out.log("FsmExecutor", "Mis en pause dans l'état : " + current_state.id.to_s)
		return status_changed(status_PAUSED)
	end

	#Arrêt l'automate dans son état actuel
	fun stop: FsmStatus do
		#Affichage de l'état dans lequel l'automate a été stoppé
		out.log("FsmExecutor", "Arrêté dans l'état : " + current_state.id.to_s)
		print "--------------------------------------"
		print "Arrêt de l'automate"
		return status_changed(status_STOPPED)
	end

	#Méthode appelé lors du changement de statut de l'automate
	#1.EN COURS D'EXECUTION, 2.EN PAUSE (reprise autorisée), 3.STOPPE (reprise non autorisée)
	fun status_changed(status: Int): FsmStatus do
		return current_status.change(status)
	end

	#Retourne l'état actuel de l'automate
	fun current_state: nullable FsmState is abstract
	#Retourne le statut actuelle de l'automate
	fun current_status: FsmStatus is abstract

	fun reset is abstract
	fun initial_state: FsmState is abstract
	fun is_final(state: FsmState): Bool is abstract
	fun clone: nullable AbstractAutomaton[E]  is abstract
	fun accept_entry(input: E): Bool  is abstract
	fun accept_word(sequence: List[E]): Int  is abstract

	#Active le mode verbeux de l'automate - chaque étape est imprimée sur la console
	fun trace(active: Bool) do out.is_activated = true

	#Permet d'exporter l'automate dans un format répandu (.dot)
	#Retourne un booléen indiquant si l'export a fonctionné
	fun export(filename: String, graph_color: nullable String): Bool do
		var dot_graph = new DotGraph.directed(filename)

		#ADD NODES DEFS
		for id, state in get_states do
			var initial = false
			var final = false
			if state == initial_state then initial = true
			if is_final(state.as(not null)) then final = true
			dot_graph.add_node_state(id.to_s, initial, final)
		end

		#ADD EDGES DEFS
		for transition in get_transitions do
			var source = transition.get_source.id.to_s
			var target = transition.get_target.id.to_s
			var lab = transition.get_label.to_s
			dot_graph.add_edge(source, target, lab)
		end
		if graph_color != null then dot_graph.color = graph_color
		dot_graph.export
		#todo : un vrai test pour vérifier si l'export a fonctionné
		return true
	end
end

#On essaie ce qu'on a sous la main pour simuler un enum
class FsmOperation
	var _union  = false
	var _concat = false
	#comment
	init do end
	init union do _union = true
	init concat do _concat = true

	fun isUnion: Bool do return _union
	fun isConcat: Bool do return _concat
end

class CompositeAutomaton
	super AbstractAutomaton[Object]
	var left_op : AbstractAutomaton[Object]
	var right_op : AbstractAutomaton[Object]
	var operation : FsmOperation
	var given_sequence = new List[Object]
	#var accepted_sequence = new List[Object]
	var free_state : nullable FsmState
	var epsilon_lbl = "epsilon"
	var free_state_lbl = "FREE"

	#Initialisateur d'un automate composite
	#param left : automate opérande de gauche
	#param right : automate opérande de droite
	#param op : opérateur à appliquer entre les opérandes
	init(left: AbstractAutomaton[Object], right: AbstractAutomaton[Object], op: FsmOperation) do
		left_op = left
		right_op = right
		operation = op
		if op.isUnion then create_free_state
	end

	#Permet de démarrer l'automate composite
	redef fun start: FsmStatus do
		#si l'opération à appliquer est une union/somme
		#ajout d'un etat initial + 2 transitions epsilon
		#une vers etat initial a et l'autre vers initial b
		if operation.isUnion then
			#todo

		#sinon si l'opération à appliquer est un produit/concaténation
		#l'état initial ne peut être
		else if operation.isConcat then

		end
		return new FsmStatus(status_STOPPED)
	end

	#Remettre à zero un automate composite revient
	#à remettre à zero chacun de ses enfants
	#Note si un des enfants est lui même est un composite
	#alors la remise à zéro est recursive
	redef fun reset do
		left_op.reset
		right_op.reset
	end

	private fun create_free_state do
		if free_state != null then return
		var new_state = new FsmState(free_state_lbl)
		#comment
		var tr = new EpsilonTransition(epsilon_lbl, new_state)
		tr.set_target(left_op.initial_state)
		new_state.add_transition(tr)
		#comment
		tr = new EpsilonTransition(epsilon_lbl, new_state)
		tr.set_target(right_op.initial_state)
		new_state.add_transition(tr)
		free_state = new_state
	end

	redef fun initial_state: FsmState do
		#si c'est une opération d'union
		#l'automate ajoute lui même un état initial
		if operation.isUnion then
			return free_state.as(not null)
		#si c'est une opération de concaténation
		#l'automate résultant ne peut qu'avoir l'état initial
		#de l'automate gauche
		else #if operation.isConcat then
			return left_op.initial_state
		end
	end

	redef fun is_final(state: FsmState): Bool do
		#si c'est une opération d'union
		#l'automate résultant peut avoir des états finaux
		#issus de l'automate gauche et droit
		if operation.isUnion then
			if left_op.is_final(state) then return true
			if right_op.is_final(state) then return true
		#si c'est une opération de concaténation
		#l'automate résultant ne peut avoir des états finaux
		#que de l'automate droit
		else if operation.isConcat then
			if right_op.is_final(state) then return true
		end
		return false
	end

	redef fun clone: nullable AbstractAutomaton[Object]  is abstract
	redef fun accept_entry(input: Object): Bool  is abstract

	redef fun accept_word(sequence: List[Object]): Int do
		if sequence.length == 0 then return 1
		var left_compatibility = true
		var right_compatibility = true
		var left_acceptance = false
		var right_acceptance = false
		var debugBuf = new Buffer

		if operation.isUnion then

			for symbol in sequence do
				debugBuf.append(symbol.to_s + " ")
				if left_op.is_acceptable(symbol) == false then
					left_compatibility = false
				end
				if right_op.is_acceptable(symbol) == false then
					right_compatibility = false
				end
			end

			out.log("CompositeAutomaton", "Séquence passée : " + debugBuf.to_s)

			if left_compatibility then
				out.log("CompositeAutomaton", "L'automate interne gauche travaille sur un alphabet compatible avec la séquence passée")
				left_acceptance = accept_left(sequence)
				out.log("CompositeAutomaton", "L'automate interne gauche accepte la séquence passée")
			end

			if right_compatibility then
				out.log("CompositeAutomaton", "L'automate interne droit travaille sur un alphabet compatible avec la séquence passée")
				right_acceptance = accept_right(sequence)
				out.log("CompositeAutomaton", "L'automate interne droit accepte la séquence passée")
			end

			if left_acceptance or right_acceptance then
				out.log("CompositeAutomaton", "Somme d'automates : Séquence acceptée")
				return 1
			else
				out.log("CompositeAutomaton", "Somme d'automates : Séquence refusée")
				return 0
			end
		end
		if operation.isConcat then
			var left_list = new List[Object]
			var right_list = new List[Object]
			var is_begin = true
			var common_alphabet = true

			for symbol in sequence do
				debugBuf.append(symbol.to_s + " ")
				var left_accept = left_op.is_acceptable(symbol)
				var right_accept = right_op.is_acceptable(symbol)
				#si c'est le même alphabet on ne peut pas séparer
				#objectivement les symboles de la séquence - on flag
				#deux executions partielles nécessaires
				#execution partielle = état final atteint avant d'avoir terminé la séquence
				if  left_accept != true or right_accept != true then
					common_alphabet = false
				end
				#ajout des symboles à la premiere partie de l'alphabet
				#la première partie de l'alphabet est destinée à être
				#acceptée par l'automate gauche
				if left_accept and is_begin then
					left_list.add(symbol)
				else if left_accept == false and right_accept and is_begin then
					is_begin = false
					right_list.add(symbol)
				else if right_accept and is_begin == false then
					right_list.add(symbol)
				end
			end
			out.log("CompositeAutomaton", "Séquence passée : " + debugBuf.to_s)

			if left_list.length == 0 and right_list.length == 0 then
				return 0
			else if left_list.length == 0 then
					left_acceptance = true
					right_acceptance = accept_right(right_list)
			else if right_list.length == 0 then
					right_acceptance = true
					left_acceptance = accept_left(left_list)
			else
				if common_alphabet then
					var left_acceptance_index = accept_part_left(left_list, true)
					if left_acceptance_index < 0 or left_acceptance_index == 1 then
						left_acceptance = true
						right_list = new List[Object]
						var i = 0
						while i < left_list.length do
							if i >= (0- left_acceptance_index) then break
							right_list.add(left_list[i])
							i+=1
						end
						right_acceptance = accept_right(right_list)
					end
				else
					left_acceptance = accept_left(left_list)
					right_acceptance = accept_right(right_list)
				end
			end

			if left_acceptance and right_acceptance then
				out.log("CompositeAutomaton", "Produit d'automates : Séquence acceptée")
				return 1
			else
				out.log("CompositeAutomaton", "Produit d'automates : Séquence refusée")
				return 0
			end
		end
		return 0
	end

	private fun accept_part_left(sequence: List[Object], partial: Bool): Int do
		left_op.reset
		left_op.start
		return left_op.accept_word(sequence)
	end

	#attention - usage interne uniquement
	#à utiliser dans un ordre définit
	private fun accept_left(sequence: List[Object]): Bool do
		var result = accept_part_left(sequence, false)
		if result == 1 then return true
		return false
	end

	#attention - usage interne uniquement
	#à utiliser dans un ordre définit
	private fun accept_right(sequence: List[Object]): Bool do
		right_op.reset
		right_op.start
		var result = right_op.accept_word(sequence)
		if result == 1 then return true
		return false
	end

	redef fun get_states do
		var total_states = new HashMap[Object, nullable FsmState]
		#comment
		if operation.isUnion then total_states[free_state_lbl] = free_state
		for key, value in left_op.get_states do
			total_states[key] = value
		end
		for key, value in right_op.get_states do
			total_states[key] = value
		end
		return total_states
	end

	redef fun get_final_states: Set[FsmState] do
		var final_states = new HashSet[FsmState]
		for st in left_op.get_final_states do
			final_states.add(st)
		end
		for st in right_op.get_final_states do
			final_states.add(st)
		end
		return final_states
	end

	redef fun get_transitions do
		var total_transitions = new HashSet[FsmTransition]
		#comment
		if operation.isUnion then
			for tr in free_state.as(not null).get_transitions do
				total_transitions.add(tr)
			end
		end
		#comment
		if operation.isConcat then
			for final_st in left_op.get_final_states do
				var tr = new EpsilonTransition(epsilon_lbl, final_st)
				tr.set_target(right_op.initial_state)
				total_transitions.add(tr)
			end
		end
		for tr in left_op.get_transitions do
			total_transitions.add(tr)
		end
		for tr in right_op.get_transitions do
			total_transitions.add(tr)
		end
		return total_transitions
	end

	#redef fun export(filename: String, graph_color: nullable String): Bool do
	#	return left_op.export(filename, graph_color)
	#end
end

#Helper permettant d'executer l'automate
class FsmExecutor[E]
	super AbstractAutomaton[E]
	redef type AlphabetType : E

	#usage interne uniquement - plus pratique pour générer un .dot
	var cached_states : HashMap[Object, nullable FsmState]
	var cached_transitions : HashSet[FsmTransition]

	var async_exec = false
	var cur_state : nullable FsmState
	var final_states : Set[FsmState]
	var accepted = true
	var given_sequence = new List[E]
	var accepted_sequence = new List[E]
	var init_state : FsmState
	var cur_status  = new FsmStatus(3)

	#Retourne si l'automate doit s'exécuter selon umodèle "asynchrone"
	fun is_async: Bool do return async_exec

	#Retourne si l'automate doit s'exécuter selon umodèle "synchrone"
	fun is_async=(async: Bool) do async_exec = async

	#Initialisateur
	#param1 : état initial de l'automate
	#param2 : ensemble des états finaux de l'automate
	init(init_state: FsmState,
			final_states: Set[FsmState],
			cached_states : HashMap[Object, nullable FsmState],
			cached_transitions : HashSet[FsmTransition]) do
		self.init_state = init_state
		self.final_states = final_states
		self.cached_states = cached_states
		self.cached_transitions = cached_transitions
		reset
	end

	#Réinitialise le contexte d'exécution de l'automate
	#Si l'automate a pour vocation d'être réutilisé, il est conseillée d'utiliser cette méthode
	#plutôt que de rappeler la méthode build du FsmBuilder associé
	redef fun reset do
		cur_state = init_state
		given_sequence = new List[E]
		accepted_sequence = new List[E]
		status_changed(status_STOPPED)
	end

	redef fun initial_state: FsmState do return init_state

	redef fun current_state: nullable FsmState do return cur_state

	redef fun current_status: FsmStatus do return cur_status

	redef fun get_final_states: Set[FsmState] do return final_states

	#Indique si l'état passé en paramètre est un état final de l'automate considéré
	redef fun is_final(state: FsmState): Bool do
		for cur_state in final_states do
			if cur_state == state then return true
		end
		return false
	end

	#Méthode appelée lorsque l'automate change d'état
	fun state_changed do
		out.log("FsmExecutor", "Passage dans l'état : " + current_state.id.to_s)
	end

	#Clone l'automate -- plusieurs transitions avec la même étiquette
	redef fun clone: nullable FsmExecutor[E] do return null

	#Permet d'exécuter l'automate de manière "asynchrone"
	#Utilisé en collaboration avec la méthode is_accepted permet
	#d'inspecter et de modifier dynamiquement le comportement de l'automate
	redef fun accept_entry(input: E): Bool do
		if cur_status == status_STOPPED then
			return false
		end
		if is_async == false then
			print "Impossible d'appeler la méthode accept_entry sur un automate synchrone"
			return false
		end
		given_sequence.add(input)
		if accept(input) == false then
			status_changed(status_STOPPED)
			return false
		end
		if is_accepted == 1 then
			status_changed(status_STOPPED)
		else status_changed(status_PAUSED)
		return true
	end

	#Retourne vrai si le mot passé en paramètre (suite de symboles de l'alphabet) est accepté par l'automate
	redef fun accept_word(sequence: List[E]): Int do
		if is_async then
			print "Impossible d'appeler la méthode accept_word sur un automate asynchrone"
			return 0
		end

		given_sequence = sequence

		#si le mot/la séquence envoyée est vide
		#le mot vide est accepté par l'automate
		if given_sequence.length == 0 then
			stop
			return 1
		end

		#Pour chaque symbole de la séquence
		var itor = sequence.iterator
		#var symbol : E

		#while itor.is_ok do
		#	symbol = itor.item
		#	print "symbole a traiter : " + symbol.to_s + ", id : " +  symbol.object_id.to_s
		#	if accept(symbol) == false then
		#		out.log("FsmExecutor", "Le symbole " + symbol.to_s + " a été refusé")
		#		accepted = false
		#		break
		#	end
		#	accepted_sequence.add(symbol)
		#	itor.next
		#end
		for symbol in sequence do
			if accept(symbol) == false then
				out.log("FsmExecutor", "Le symbole " + symbol.to_s + " a été refusé")
				accepted = false
				break
			end
			accepted_sequence.add(symbol)
		end
		return is_accepted
	end

	#Retourne vrai si le "mot" est accepté par l'automate
	#Reinitialisation (reset) nécessaire afin de reconnaître un autre mot
	private fun is_accepted: Int do
		#Si le dernier symbole a été accepté et l'état actuel est final
		if accepted and is_final(current_state.as(not null)) then
			if accepted_sequence.equals(given_sequence) then
				out.log("FsmExecutor", "Séquence acceptée")
				return 1
			else
				out.log("FsmExecutor", "Erreur : Etat final atteint pour le symbole accepté mais séquence reconnue incomplète")
				return accepted_sequence.length - given_sequence.length
			end
		end
		out.log("FSMExecutor", "Séquence refusée")
		return 0
	end

	#Effectue les différents actions nécessaire à la transition entre états
	private fun accept(symbol: E): Bool do
		out.log("FsmExecutor trace", "Symbole reçu : " + symbol.to_s)
		out.log("FsmExecutor trace", "Symboles acceptables : " + cur_state.accepted_symbols)
		for trans in cur_state.get_transitions do
			#à régler
			if trans.get_label == symbol then
				trans.notify
				cur_state = trans.get_target
				state_changed
				return true
			end
		end
		return false
	end

	redef fun get_states: HashMap[Object, nullable FsmState] do return cached_states

	redef fun get_transitions: HashSet[FsmTransition] do return cached_transitions
end

#Représente une transition entre deux états
#Utilisé durant la création de l'automate
#Remplacé par FsmTransition une fois l'objet FsmState cible connu
class Internal_Transition
	#Etat source de la transition
	#à la sortie de cet état on exécute la méthode on_exit()
	var _source : FsmState

	#Etat cible de la transition
	#à l'entrée de cet état on exécute la méthode on_enter()
	var _target : nullable FsmState

	#Evenement ayant causé le changement d'état
	var _label : Object

	#Retourne l'étiquette de la transition
	fun get_label : Object do return _label

	#Retourne l'état source de la transition
	fun get_source : FsmState do return _source

	#Avertit l'état source de la sortie
	#Avertir l'état destination de l'entrée
	fun notify do
		_source.quit
		print "--------------------------------------"
		_target.enter
	end

	#Initialisateur
	init(tag: Object, source: FsmState) do
		_label = tag
		_source = source
	end
end

#Représente une transition entre deux états
#Créé en interne à partir d'une Internal_Transition
#Une fois l'état cible connu et validé (avant simple id, maintenant objet FsmState)
class FsmTransition
	super Internal_Transition
	#Définit l'état ciblé par le transition
	fun set_target(target: FsmState) do _target = target
	#Retourne l'état ciblé par le transition
	fun get_target : FsmState do return _target.as(not null)
end

class EpsilonTransition
	super FsmTransition
end

#Représente un état temporaire de l'automate
#Dans cette bibliothèque un état peut se voir associé à deux actions
# *Une action déclenchée avant l'entrée de l'automate dans cet état
# *Une action déclenchée après la sortie de l'automate de cet état
class FsmState
	var _id : Object
	var _enter : nullable FsmAction
	var _exit : nullable FsmAction
	var _transitions = new List[FsmTransition]

	#Initialisateur prenant en paramètre l'identifiant de l'étatS
	init(id: Object) do
		_id = id
	end

	#Méthode exécutée à l'entrée de l'état
	fun enter do
		if _enter != null then
			print "Action entrée : " + _enter.do_callback
		end
	end

	#Méthode exécutée à la sortie de l'état
	fun quit do
		if _exit != null then
			print "Action sortie : " + _exit.do_callback
		end
	end

	#Setter pour l'action effectuée lors de l'entrée de l'automate dans cet état
	fun set_enter(action: FsmAction) do _enter = action

	#Setter pour l'action effectuée lors de la sortie de l'automate de cet état
	fun set_exit(action: FsmAction) do _exit = action

	fun add_transition(trans : FsmTransition) do _transitions.add(trans)

	fun set_transitions(transitions: List[FsmTransition]) do
		_transitions = transitions
	end

	#TOFIX : doit retourner un itérateur pour la liste de transitions (de sortie)
	#Itérateur non implémenté? On se contente de retourner naïvement la liste
	fun get_transitions : List[FsmTransition] do return _transitions

	#Retourne le nom/ l'identifiant de l'état
	fun id : Object do return _id

	#debug only
	fun accepted_symbols : String do
		var buffer = new Buffer
		for trans in _transitions do
			buffer.append(trans.get_label.to_s + ", ")
		end
		return buffer.to_s
	end

	#debug only
	fun print_transitions do
		for trans in _transitions do
			print "[" + trans.get_label.to_s + "]--->" + trans.get_target.id.to_s
		end
	end
end

#Action effectuée lors de l'entrée ou la sortie dans un état
interface FsmAction
	#Callback chargé d'appeler le code spécifique à executer
	fun do_callback : String is abstract
end

#Raffinement de l'interface Collection afin d'y ajouter une méthode de comparaison basique
redef interface Collection[E]
	#Renvoie vrai si les éléments des deux collections sont identiques et rangés dans le même ordre
	fun equals(comp: Collection[E]): Bool do
		if is_empty and comp.is_empty then return true
		if length !=  comp.length then return false
		for item in comp do
			if has(item) == false then return false
		end
		return true
	end
end
