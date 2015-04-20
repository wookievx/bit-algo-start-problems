/*
 * Klops.cpp
 *
 *  Created on: 18 kwi 2015
 *      Author: lukaszlampart
 */

#include <vector>
#include <iostream>
#include <string>
#define INF 1000000
/**
 * Class SCT - Static counting tree
 * Type T must have defined operator+
 */
template<class T>
class SCT {
private:
	// sum tree container
	std::vector<T> tab;
	int offset;
protected:
	/**
	 * Three protected methods to use inside any class inheriting
	 *
	 */
	inline int parent(int pos) {return pos/2;} // return parent of the node
	inline int leftSon(int pos) {return pos*2;}// return left son of the node
	inline int rightSon(int pos) {return pos*2+1;}// return right son of the node
private:
	/**
	 *
	 *	 Inner function responsible of answering the sum-tree query at [begin,end]
	 *	 nodel-left edge of the range of the current tree node
	 *	 noder-right edge of the range of the current tree node
	 *	 pos- current tree node
	 *	 return - sum of elements in range [begin,end]
	 */
	T inQuery(int begin,int end,int nodel,int noder,int pos);
public:
	/**
	 *  Constructor resizing inner vector tab with the smallest power of 2, greater then given parameter
	 */
	SCT(int number_of_elements);
	/**
	 * Destructor does actually nothing
	 */
	virtual ~SCT();
	/**
	 * update the element at position given by the argument counter
	 */
	void update(int counter,T value);
	/**
	 * Function returns sum of object in range [begin,end]
	 */
	T query(int begin,int end);
	/**
	 * Method returns value of the stored element at position counter
	 */
	T reverseAt(int counter);
	/**
	 * Simple toString method, returns string like: | <tree node number> <tree node value> |
	 * for all nodes in order they're stored in inner container
	 */
	std::string toString();
};
/**
 * Object inheriting from SCT<int>
 * It's methods solve the problem "Nawiasy"
 */
class SMinT : private SCT<int> {
private:
	// minimum tree container
	std::vector<int> min;
	int offset;
public:
	/**
	 * Constructor resizing inner vector tab with the smallest power of 2, greater then given parameter
	 */
	SMinT(int number_of_elements);
	/**
	 * Destructor does actually nothing
	 */
	virtual ~SMinT();
	/**
	 *  updates the minimal prefix sums in the tree
	 *  it's actually used to initialize the leafs!
	 */
	void update(int counter,int value);
	/**
	 * Reverse the value in the tree leaf
	 */
	void reverse(int counter);
	/**
	 * Method returns minimal prefix sum
	 */
	int getMin();
	/**
	 * Method return prefix sum of the entire table
	 */
	int getSum();
};

int main(){
	std::ios_base::sync_with_stdio(false);
	int n,m,k;
	std::string c;
	std::cin>>n>>m>>c;
	SMinT drzewko(n);
	for (int i=1;i<=n; i++){
		if (c[i-1]=='(') drzewko.update(i,1);
		else		   drzewko.update(i,-1);
		//just breakpoint
	}
	for (int i=0; i<m; i++){
		scanf("%d",&k);
		if (k==0){
			std::cout<<drzewko.getSum()<<" "<<drzewko.getMin()<<std::endl;
			if (drzewko.getSum()==0 && drzewko.getMin()==0) puts("TAK");
			else puts("NIE");
		}
		else{
			drzewko.reverse(k);
		}
	}
	return 0;
}

template<class T>
std::string SCT<T>::toString(){
	std::string r="Stan drzewa | ";
	for (int i=1; i<tab.size(); i++){
		r+=std::to_string(i)+" "+std::to_string(tab[i])+" | ";
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
	for (int j=1; j<i; j++) tab[j]=0; // valid all-zero SCT, modifications are just updating this tree
	offset=i/2-1;
}
template<class T>
T SCT<T>::reverseAt(int counter){
	tab[counter+offset]*=-1;
	return tab[counter+offset];
}
template<class T>
SCT<T>::~SCT() {
	// TODO Auto-generated destructor stub
}

SMinT::SMinT(int number_of_elements): SCT<int>(number_of_elements) {
	int i=1;
	while (i<number_of_elements) i*=2;
	i*=2;
	min.resize(i);
	for (int j=1; j<i; j++) min[j]=INF;
	offset=i/2-1;
}
void SMinT::update(int counter,int value){
	SCT<int>::update(counter,value);
	min[counter+offset]=query(1,counter);
	counter+=offset;
	while (counter>1){
		if (min[counter]<min[parent(counter)]) min[parent(counter)]=min[counter];
		counter=parent(counter);
	}
}
void SMinT::reverse(int counter){
	update(counter,reverseAt(counter));
}
int SMinT::getMin(){
	return min[1];
}
int SMinT::getSum(){
	return query(1,offset+1);
}
SMinT::~SMinT(){};
