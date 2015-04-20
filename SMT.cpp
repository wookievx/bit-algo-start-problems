//============================================================================
// Name        : SMT.cpp
// Author      : Lucas Lampart
// Version     : 0.5
// Copyright   : 
// Description : Static minimum tree
//============================================================================
/**
* Ważny komentarz: do rozwiązania zadania wykorzystałem drzewo licznikowo/minimum (wykorzystuje cechy obu drzew)
klasa SCT (skrót od Static Counting Tree) była częścią innego projektu (zacząłem ją tworzyć na ostatnich zajęciach koła), klasa SMT (Static Minimum Tree) dziediczy z SCT (może być chyba private modyfikator), dodałem metodę toString w poprzednim projekcie to i tu ją umieściłem. Działanie mojego algorytmu jest w miarę proste, korzystam z tej części funkcjonalności SCT, że w każdym wierzchołku drzewa trzymam sumę elementów ciągu nawiasów (jak +1,-1), które odpowiadają temu wierzchołkowi. Inicjalizacja struktury to n operacji update , które aktualizują  wierzchołki drzewa SMT (więc i drzewa SCT), koszt aktualizacj1 wierzchołków SCT jest 
O(log (n)) (SCT jest początkowo wypełnione zerami więc operacja update na pustym drzewie jest prawidłowa, SMT jest zainicjowane liczbą, która przekracza możliwe osiągalne wartości dla naszych sum jest więc również operacja update jest zawsze poprawna) , update SMT jest również kosztu O(log(n))
*/
#include <iostream>
#include <string>
#include <vector>
#define INF 2000000;
using namespace std;
//definitions
template<class T>
class SCT {
protected:
	vector<T> tab;
	int offset;
	inline int parent(int pos) {return pos/2;}
	inline int leftSon(int pos) {return pos*2;}
	inline int rightSon(int pos) {return pos*2+1;}
	T inQuery(int begin,int end,int nodel,int noder,int pos);
public:
	SCT(int number_of_elements);
	virtual ~SCT();
	void update(int counter,T value);
	T query(int begin,int end);
	string toString();
};

class SMT : public SCT<int> {
private:
	int* min;
public:
	SMT(int l):SCT(l){
		min=new int[tab.size()];
		for (int i=0; i<tab.size(); i++){
			min[i]=INF;
		}
	}
	~SMT(){
		delete [] min;
	}
	int getMin(){
		return min[1];
	}
	int getSum(){
		return query(1,offset+1);
	}
	/*
	*Krótki opis działania:
	* 1. wykonaj update na SCT (koszt log(n))
	* 2. ustaw tablicę min[i]=v i aktualizuj wartości wierzchołków w drzewie (mają pamiętać najmniejszą sumę prefiksową w ich 		* przedziale: 	  a
                        /  \
                    |xxx..|xxx..|
	xxx- najmniejsza suma prefiksowa przedziału, wylicza odpowiednie wyrażenie
	*/
	void update(int i,int v){ 
		SCT<int>::update(i,v);
		i+=offset;
		min[i]=v;
		while (i>1){
			i=parent(i);
			min[i]=min[leftSon(i)]<(tab[leftSon(i)]+min[rightSon(i)]) ? min[leftSon(i)] : tab[leftSon(i)]+min[rightSon(i)];
		}
	}
	string toString (){
		string s="| ";
		for (int i=1; i<tab.size(); i++){
			s+=to_string(i)+" "+to_string(min[i])+" |";
		}
		return SCT<int>::toString()+"\n"+s;
	}
};


int main() {
	ios_base::sync_with_stdio(false);
	int n,m,k;
	string miks;
	cin>>n>>m>>miks;
	SMT dr(n);
	for (int i=0; i<n; i++){
		dr.update(i+1,(miks[i]=='(' ? 1 : -1));
	}
	for (int i=0; i<m; i++){
		cin>>k;
		if (k==0) (dr.getMin()==0 && dr.getSum()==0 ? cout<<"TAK\n": cout<<"NIE\n");
		else {
			miks[k-1]=(miks[k-1]=='(' ? ')': '(');
			dr.update(k,(miks[k-1]=='(' ? 1 : -1));
		}
	}
	return 0;
}
// declarations
template<class T>
string SCT<T>::toString(){
	string r="Stan drzewa | ";
	for (int i=1; i<tab.size(); i++){
		r+=to_string(i)+" "+to_string(tab[i])+" | ";
	}
	return r;
}
template<class T>
T SCT<T>::inQuery(int begin,int end,int nodel,int noder,int pos){
	//printf("Wywolanie dal pozycji %d [ %d , %d , %d , %d ]\n",pos,begin,end,nodel,noder);  lame but in this case pretty efficient debug
	if (begin==nodel && end==noder) return tab[pos];
	int pivot=(nodel+noder)/2;
	return (pivot<begin ? 0 : inQuery(begin,(pivot<end ? pivot : end ),nodel,pivot,leftSon(pos))) // recursion specifications
		+ (end<++pivot ? 0 : inQuery((pivot>begin ? pivot : begin),end,pivot,noder,rightSon(pos)));
}
template<class T>
void SCT<T>::update(int counter,T value){
	counter+=offset;
	tab[counter]=value;
	while (counter>0){
		counter=parent(counter);
		tab[counter]=tab[leftSon(counter)]+tab[rightSon(counter)];
	}
}
template<class T>
T SCT<T>::query(int begin,int end){
	return inQuery(begin,end,1,offset+1,1);
}

template<class T>
SCT<T>::SCT(int number_of_elements) {
	int i=1;
	while (i<number_of_elements) i*=2;
	i*=2;
	tab.resize(i);
	for (int i=1; i<i; i++) tab[i]=0; // valid all-zero SCT, modifications are just updating this tree
	offset=i/2-1;
}
