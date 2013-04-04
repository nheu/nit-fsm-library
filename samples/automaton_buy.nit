module automaton_buy
import fsm
import url

#Action effectuée avant l'entrée dans l'état de la page /infos.aspx
class PageEnter_Infos
	super FsmAction
	redef fun do_callback do return "Demande page : Informations de facturation"
end

#Action effectuée après la sortie de l'état de la page /infos.aspx
class PageExit_Infos
	super FsmAction
	redef fun do_callback do return "Page quittée : Informations facturation"
end

#Action effectuée avant l'entrée dans l'état de la page /payment.aspx
class PageEnter_Payment
	super FsmAction
	redef fun do_callback do return "Demande page : Mode de paiement"
end

#Action effectuée après la sortie de l'état de la page /payment.aspx
class PageExit_Payment
	super FsmAction
	redef fun do_callback do return "Page quittée : Mode de paiement"
end

#Action effectuée avant l'entrée dans l'état de la page /offer.aspx
class PageEnter_Offer
	super FsmAction
	redef fun do_callback do return "Demande page : Code de reduction"
end

#Action effectuée après la sortie de l'état de la page /offer.aspx
class PageExit_Offer
	super FsmAction
	redef fun do_callback do return "Page quittée : Code de reduction"
end

#Action effectuée avant l'entrée dans l'état de la page /purchase.aspx
class PageEnter_Purchase
	super FsmAction
	redef fun do_callback do return "Demande page : Résumé facturation"
end

#Action effectuée après la sortie de l'état de la page /purchase.aspx
class PageExit_Purchase
	super FsmAction
	redef fun do_callback do return "Page quittée : Résumé facturation"
end

#Action effectuée avant l'entrée dans l'état de la page /confirmation.aspx
class PageEnter_Confirmation
	super FsmAction
	redef fun do_callback do return "Demande page : Confirmation paiement"
end

#Action effectuée après la sortie de l'état de la page /confirmation.aspx
class PageExit_Confirmation
	super FsmAction
	redef fun do_callback do return "Page quittée : Confirmation paiement"
end

class AutomatonBuy
	#Définition des états
	var state_infos = "INFOS"
	var state_payment = "PAYMENT"
	var state_offer = "OFFER"
	var state_purchase = "PURCHASE"
	var state_confirmation = "CONFIRMATION"
	#Définition des étiquettes des transitions
	var urlInfos = new ResourceLocator("http", "://", "www.nitgoodies.com/", "infos.aspx")
	var urlPayment = new ResourceLocator("http", "://", "www.nitgoodies.com/", "payment.aspx")
	var urlOffer = new ResourceLocator("http", "://", "www.nitgoodies.com/", "offer.aspx")
	var urlPurchase = new ResourceLocator("http", "://", "www.nitgoodies.com/", "purchase.aspx")
	var urlConfirmation = new ResourceLocator("http", "://", "www.nitgoodies.com/", "confirmation.aspx")

	fun get: nullable FsmExecutor[ResourceLocator] do
		###########################
		#Construction de l'automate
		###########################

		#Définition de l'alphabet - Liste des différents symboles valides
		var alphabet = new Alphabet[ResourceLocator]
		alphabet.add(urlInfos)
		alphabet.add(urlPayment)
		alphabet.add(urlOffer)
		alphabet.add(urlPurchase)
		alphabet.add(urlConfirmation)
		var automaton_bldr = new FsmBuilder[ResourceLocator](alphabet)
		automaton_bldr.trace(true)

		#Création de l'état initial - page informations de facturation
		automaton_bldr.get_state_builder(state_infos).
						set_initial(true).
						on_enter(new PageEnter_Infos).
						on_exit(new PageExit_Infos).
						set_transition(urlPayment, state_payment).
						commit

		#Création d'un état intermédiaire - page choix mode paiement
		automaton_bldr.get_state_builder(state_payment).
						on_enter(new PageEnter_Payment).
						on_exit(new  PageExit_Payment).
						set_transition(urlInfos, state_infos).
						set_transition(urlOffer, state_offer).
						set_transition(urlPurchase, state_purchase).
						commit

		#Création d'un état intermédiaire - page saisie code reduction
		automaton_bldr.get_state_builder(state_offer).
						on_enter(new PageEnter_Offer).
						on_exit(new  PageExit_Offer).
						set_transition(urlPayment, state_payment).
						commit

		#Création d'un état intermédiaire - page résumé facturation
		automaton_bldr.get_state_builder(state_purchase).
						on_enter(new PageEnter_Purchase).
						on_exit(new  PageEnter_Purchase).
						set_transition(urlPayment, state_payment).
						set_transition(urlInfos, state_infos).
						set_transition(urlConfirmation, state_confirmation).
						commit

		#Création de l'état final - page de confirmation paiement
		automaton_bldr.get_state_builder(state_confirmation).
						set_final(true).
						on_enter(new PageEnter_Confirmation).
						on_exit(new PageExit_Confirmation).
						commit

		return automaton_bldr.build
	end

	#tests only
	fun sample_execution(automaton: FsmExecutor[ResourceLocator]) do
		execute(automaton, sample_buy_workflow)
	end

	fun sample_buy_workflow: List[ResourceLocator] do
		var buy_workflow = new List[ResourceLocator]
		buy_workflow.add(urlPayment)
		buy_workflow.add(urlPurchase)
		buy_workflow.add(urlConfirmation)
		return buy_workflow
	end

	fun execute(automaton: FsmExecutor[ResourceLocator], sequence: List[ResourceLocator]) do
		########################
		#Exécution de l'automate
		########################
		automaton.trace(true)
		automaton.start
		automaton.accept_word(sequence)
	end
end

var fsa = new AutomatonBuy
var intern_automaton = fsa.get.as(not null)
fsa.sample_execution(intern_automaton)
intern_automaton.export("automaton_buy", "red")
