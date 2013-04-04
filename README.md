nit-fsm-library
===============

A [nit](http://nitlanguage.org) library for manipulating finite-state machine

Some Nit Fsm Library features:
 * generic alphabet construction.
 * construction of and automaton over this alphabet.
 * "asynchronous" and "synchronous" automaton execution
 * automata combination : union and concat operation
 * export function : state diagram (.dot files)

Requirement:
 * a working [nit](http://nitlanguage.org) installation 
 * [dot](http://www.graphviz.org/)	to enable graphes display

Important files and directory:

 * doc/       Documentation
 * dot/	      Dot generation convenience class
 * fsm/	      The Fsm Library
 * samples/	  Code examples
 * makefile   Makefile assuming an existing environment variable set to a valid nit installation
 
Samples
 * $ make automaton_shop #build and execute an automaton representing a shopping workflow
 * $ make automaton_buy #build and execute an automaton representing a payment workflow
 * $ make automaton_sum #automaton_shop + automaton_buy : shopping OR payment
 * $ make automaton_product #automaton_shop * automaton_buy : shopping AND payment
