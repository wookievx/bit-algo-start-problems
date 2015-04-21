/*
 * problem4.cpp
 * Solution to problem "Kodowanie permutacji"
 *  Created on: 21 kwi 2015
 *      Author: lukaszlampart
 */
#include <cstdio>
using namespace std;
/*
 * SSPT - drzewo statystyk pozycyjnych
 */
class SSPT {
private:
	int *t;
	size_t size;
	inline size_t parent(size_t x) { return x>>1;}
	inline size_t leftSon(size_t x){ return x<<1;}
	inline size_t rightSon(size_t x){return (x<<1)+1;}
public:
	// alokacja pamięci i zerowanie tablicy
	SSPT(size_t l){
		t=new int[2*(size=1<<l)];
		for (int i=1; i<2*size; i++) t[i]=0;
		size--;
	}
	~SSPT(){
		delete [] t;
	}
	// najprostsza forma inicjalizaci (złożoność jest i tak nlog(n))
	void add(size_t i){
		i+=size;
		t[i]++;
		while (i>1){
			i=parent(i);
			t[i]++;
		}
	}
	// prosta forma usunięcia elementu z drzewa
	void remove(size_t i){
		i+=size;
		t[i]--;
		while (i>1){
			i=parent(i);
			t[i]--;
		}
	}
	// uzyskaj numer pozycji na której znajduje się aktualna i-ta wartość (0<=pos(numb)<n)
	size_t pos(int numb){
		size_t i=1;
		while (i<=size){
			if (t[leftSon(i)]>=numb) i=leftSon(i);
			else {
				numb-=t[leftSon(i)];
				i=rightSon(i);
			}
		}
		return i-size-1;
	}
};
int codeTab[300001];
int main(){
	int n;
	bool y=false;
	scanf("%d",&n);
	SSPT t(n);
	for (int i=1; i<=n; i++){
		t.add(i);
		scanf("%d",codeTab+i);
		if (codeTab[i]<0 || codeTab[i]>=i) y=true;
	}
	if (y){
		printf("NIE\n");
		return 0;
	}
	for (int i=n; i>0; i--){
		codeTab[i]=n-t.pos(codeTab[i]+1);
		t.remove(n-codeTab[i]+1);
	}
	for (int i=1; i<=n; i++) printf("%d\n",codeTab[i]);
	return 0;
}


