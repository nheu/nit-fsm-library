###################################################
# Fichier makefile pour le TP2 du cours INF7845
# Bibliotheque de gestion d'automates
# Date : Mars 2013
# Auteur : Nathan
###################################################

# define nit interpreter path
NI = ~/_git/nit[origin]/bin/nit
RM = rm -rf

# define temp dir to compiled files
TMP = .tmp/
# default nit module launched
DEFAULT = automaton_shop
TESTS = tests
# dot interpreter
DOT = xdot

.nit: $(NI) $*.nit
	
SUFFIXE = .nit

MODULES = dot/*$(SUFFIXE) fsm/*$(SUFFIXE) samples/*$(SUFFIXE) 

default: init	
	$(NI) $(TMP)automaton_buy$(SUFFIXE)
	$(NI) $(TMP)automaton_shop$(SUFFIXE)
	$(DOT) automaton_shop.dot&	
	$(DOT) automaton_buy.dot&	

init: clean
	cp $(MODULES) $(TMP)
	cd $(TMP)

tests: init
	$(NI) $(TESTS)$(SUFFIXE)	

automaton_buy: init 
	$(NI) $(TMP)automaton_buy$(SUFFIXE)
	$(DOT) automaton_buy.dot&	
	
automaton_shop: init 
	$(NI) $(TMP)automaton_shop$(SUFFIXE)
	$(DOT) automaton_shop.dot&	

automaton_ops: init
	$(NI) $(TMP)automaton_ops$(SUFFIXE)
	$(DOT) automaton_shop.dot&	
	$(DOT) automaton_buy.dot&	
	$(DOT) automaton_sum.dot&
	$(DOT) automaton_product.dot&
clean: 
	$(RM) $(TMP)
	mkdir $(TMP)
