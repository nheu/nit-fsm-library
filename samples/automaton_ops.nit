module automaton_ops
import fsm
import automaton_shop
import automaton_buy
import url

###################
#création automates
###################
#Automate - shopping
var shop_process = new AutomatonShop
var fsa_shop = shop_process.get.as(not null)

#Automate - paiement
var buy_process = new AutomatonBuy
var fsa_buy = buy_process.get.as(not null)

#Automate composé - shopping + paiement
var fsa_sum = new CompositeAutomaton(fsa_shop, fsa_buy, new FsmOperation.union)

#Automate composé - shopping * paiement
var fsa_product = new CompositeAutomaton(fsa_shop, fsa_buy, new FsmOperation.concat)

#################################
#séquences de travail
#################################
var shop_workflow = shop_process.sample_shop_workflow
var buy_workflow = buy_process.sample_buy_workflow
#liste composée de symbole de plusieurs alphabets
#mot reconnu par une composition d'automates
var hybrid_list = new List[Object]
hybrid_list.add_all(shop_workflow)
#hybrid_list.add_all(buy_workflow)

####################
#activation du trace
####################
#fsa_shop.trace(true)
#fsa_buy.trace(true)
fsa_sum.trace(true)
fsa_product.trace(true)

##########################
#exécution automate - shop
##########################
#shop_process.sample_execution(fsa_shop)
#fsa_shop.accept_word(shop_workflow)

##########################
#exécution automate - buy
##########################
#buy_process.sample_execution(fsa_buy)
#fsa_buy.accept_word(buy_workflow)

################################
#exécution automate - shop + buy
#La somme de deux automates A et B est un automate C ayant pour
#séquences validantes l'union des séquences validantes de A et B
################################
fsa_sum.start
fsa_sum.accept_word(hybrid_list)

################################
#exécution automate - shop * buy
#Le produit de deux automates A et B est un automate C ayant pour
#séquences validantes les concaténations de séquences validantes de A
#avec les séquences validantes de B en respectant cet ordre.
################################
fsa_product.start
fsa_product.accept_word(hybrid_list)

###############
#génération dot
###############
fsa_shop.export("automaton_shop", "blue")
fsa_buy.export("automaton_buy", "red")
fsa_sum.export("automaton_sum", "purple")
fsa_product.export("automaton_product", "orange")

