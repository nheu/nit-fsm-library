module automaton_shop
import fsm
import url

#Action effectuée avant l'entrée dans l'état de la page /index.aspx
class PageEnter_Index
	super FsmAction
	redef fun do_callback do return "Demande page : Accueil - Liste des produits"
end

#Action effectuée après la sortie de l'état de la page /index.aspx
class PageExit_Index
	super FsmAction
	redef fun do_callback do return "Page quittée : Accueil"
end

#Action effectuée avant l'entrée dans l'état de la page /product.aspx
class PageEnter_Product
	super FsmAction
	redef fun do_callback do return "Demande page : Détail article"
end

#Action effectuée après la sortie de l'état de la page /product.aspx
class PageExit_Product
	super FsmAction
	redef fun do_callback do return "Page quittée : Détail article"
end

#Action effectuée avant l'entrée dans l'état de la page /scart.aspx
class PageEnter_Cart
	super FsmAction
	redef fun do_callback do return "Demande page : Panier"
end

#Action effectuée après la sortie de l'état de la page /cart.aspx
class PageExit_Cart
	super FsmAction
	redef fun do_callback do return "Page quittée : Panier"
end

#Action effectuée avant l'entrée dans l'état de la page /order.aspx
class PageEnter_Resume
	super FsmAction
	redef fun do_callback do return "Demande page : Résumé commande"
end

#Action effectuée après la sortie de l'état de la page /order.aspx
class PageExit_Resume
	super FsmAction
	redef fun do_callback do return "Page quittée : Résumé commande"
end

#Action effectuée avant l'entrée dans l'état de la page /confirm.aspx
class PageEnter_Validate
	super FsmAction
	redef fun do_callback do return "Demande page : Validation commande"
end

#Action effectuée après la sortie de l'état de la page /confirm.aspx
class PageExit_Validate
	super FsmAction
	redef fun do_callback do return "Page quittée : Validation commande"
end

class AutomatonShop
	#Définition des états
	var state_index = "INDEX"
	var state_product = "PRODUCT"
	var state_cart = "CART"
	var state_resume = "ORDER"
	var state_validation = "CONFIRM"
	#Définition des étiquettes des transitions
	var urlIndex = new ResourceLocator("http", "://", "www.nitgoodies.com/", "index.aspx")
	var urlProduct = new ResourceLocator("http", "://", "www.nitgoodies.com/", "product.aspx")
	var urlCart = new ResourceLocator("http", "://", "www.nitgoodies.com/", "cart.aspx")
	var urlResumeOrder = new ResourceLocator("http", "://", "www.nitgoodies.com/", "order.aspx")
	var urlValidation = new ResourceLocator("http", "://", "www.nitgoodies.com/", "confirm.aspx")

	fun get: nullable FsmExecutor[ResourceLocator] do
		###########################
		#Construction de l'automate
		###########################
		#Définition de l'alphabet - Liste des différents symboles valides
		var alphabet = new Alphabet[ResourceLocator]
		alphabet.add(urlIndex)
		alphabet.add(urlProduct)
		alphabet.add(urlCart)
		alphabet.add(urlResumeOrder)
		alphabet.add(urlValidation)
		var automaton_bldr = new FsmBuilder[ResourceLocator](alphabet)
		automaton_bldr.trace(true)

		#Création de l'état initial - page d'accueil, liste des produits
		automaton_bldr.get_state_builder(state_index).
						set_initial(true).
						on_enter(new PageEnter_Index).
						on_exit(new PageExit_Index).
						#[state_index]=="/product.apsx"==>[state_product]
						set_transition(urlProduct, state_product).
						#[state_index]=="/cart.apsx"==>[state_cart]
						set_transition(urlCart, state_cart).
						commit

		#Création d'un état intermédiaire - page de détail d'un article
		automaton_bldr.get_state_builder(state_product).
						on_enter(new PageEnter_Product).
						on_exit(new  PageExit_Product).
						#[state_product]=="/index.apsx"==>[state_index]
						set_transition(urlIndex, state_index).
						#[state_product]=="/cart.apsx"==>[state_cart]
						set_transition(urlCart, state_cart).
						commit

		#Création d'un état intermédiaire - page de contenu du panier
		automaton_bldr.get_state_builder(state_cart).
						on_enter(new PageEnter_Cart).
						on_exit(new  PageExit_Cart).
						#[state_cart]=="/index.apsx"==>[state_index]
						set_transition(urlIndex, state_index).
						#[state_cart]=="/order.apsx"==>[state_order]
						set_transition(urlResumeOrder, state_resume).
						commit

		#Création d'un état intermédiaire - page de validation du résumé
		automaton_bldr.get_state_builder(state_resume).
						on_enter(new PageEnter_Resume).
						on_exit(new  PageExit_Resume).
						#[state_resume]=="/cart.apsx"==>[state_cart]
						set_transition(urlCart, state_cart).
						#[state_product]=="/confirm.apsx"==>[state_validation]
						set_transition(urlValidation, state_validation).
						commit

		#Création de l'état final - page de confirmation de la commande
		automaton_bldr.get_state_builder(state_validation).
						set_final(true).
						on_enter(new PageEnter_Validate).
						on_exit(new PageEnter_Validate).
						commit
		return automaton_bldr.build
	end

	#tests only
	fun sample_execution(automaton: FsmExecutor[ResourceLocator]) do
		execute(automaton, sample_shop_workflow)
	end

	fun sample_shop_workflow: List[ResourceLocator] do
		var shop_workflow = new List[ResourceLocator]
		shop_workflow.add(urlProduct)
		shop_workflow.add(urlCart)
		shop_workflow.add(urlResumeOrder)
		shop_workflow.add(urlValidation)
		return shop_workflow
	end

	fun execute(automaton: FsmExecutor[ResourceLocator], sequence: List[ResourceLocator]) do
		########################
		#Exécution de l'automate
		########################

		print "\nExécution de l'automate selon un modèle synchrone"
		automaton.trace(true)
		automaton.start
		automaton.is_async = false
		automaton.accept_word(sequence)
		#automaton.export("automaton_shop", "blue")

		#ASYNC?
		#print "\nExécution de l'automate selon un modèle asynchrone"
		#automaton.reset
		#automaton.start
		#automaton.is_async = true
		#automaton.current_state.to_s
		#var result : String
		#if automaton.accept_entry(urlIndex) then
		#	result = "oui"
		#else result = "non"
		#print "(En pause) Symbole accepté : " + result
		#if automaton.accept_entry(urlProduct) then
		#	result = "oui"
		#else result = "non"
		#print "(En pause) Symbole accepté : " + result
	end
end

var fsa = new AutomatonShop
var intern_automaton = fsa.get.as(not null)
fsa.sample_execution(intern_automaton)
intern_automaton.export("automaton_shop", "blue")


