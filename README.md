nit-fsm-library
===============

A nit library for manipulating finite-state machine

*This project is developed using the nit programming language : http://nitlanguage.org
*It contains a Makefile assuming an existing environment variable set to a valid nit installation


Some Nit Fsm Library features:
 * generic alphabets construction.
 * construction of automata over this alphabet.
 * "Asynchronous" and "synchronous" automata execution
 * automata combination : union and concat operation
 * export function : state diagram (.dot files)

Requirement:
 * a working nit installation : http://nitlanguage.org 
 * dot		http://www.graphviz.org/	to enable graphes display

Important files and directory:

 *  doc/ Documentation
 *  dot/	Dot generation convenience class
 *	fsm/	The Fsm Library
 *	samples/	Code examples
 *	makefile VarS
 
Samples
 * $ make automaton_shop #build and execute an automaton representing a shopping workflow
 * $ make automaton_buy #build and execute an automaton representing a payment workflow
 * $ make automaton_sum #automaton_shop + automaton_buy : shopping OR payment
 * $ make automaton_product #automaton_shop * automaton_buy : shopping AND payment
