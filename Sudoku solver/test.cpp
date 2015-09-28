/*
 * test.cpp
 *
 *  Created on: 27 wrz 2015
 *      Author: lukaszlampart
 */


#include "sudoku.h"
#include <iostream>

int main() {
	try {
		Sudoku abc(std::cin);
		abc[0][0].field=Sudoku::Number::ONE;
		for (int i=0; i<9; i++) {
			for (int j=0; j<9; j++) {
				std::cout<<abc[i][j].field<<" ";
			}
			std::cout<<"\n";
		}
	} catch (std::exception& e) {
		std::cout<<e.what();
	}

	return 0;
}
