/*
 * Studia.cpp
 * Solution to task Studia (Potyczki algorytmiczne 2008), Objective oriented solution
 *  Created on: 16 may 2015
 *      Author: lukaszlampart
 */
#include <vector>
#include <cstdio>
#include <string>
class Solver {
private:
	/**
	 * Struct Edge is simple representation of Edge in directed Graph
	 */
	struct Edge {
		int u,v,weight;
		Edge(int u,int v,int weight){
			this->u=u;
			this->v=v;
			this->weight=weight;
		}
	};
	std::vector<Edge> edges;
	std::vector<long long> d;
	int V;
public:
	struct Solution {
		int profitNumb;
		std::vector<int> nodes;
	};
private:
	Solution solution;
public:
	inline Solver(size_t n,size_t m,size_t s): V(n){
		d.resize(n+1);
		long long plusInf=1<<31;
		for (int i=1; i<=n; i++){
			d[i]=plusInf;
		}
		d[s]=0;
	}
	inline void pushEdge(int u,int v,int weight){
		Edge e(u,v,weight);
		edges.push_back(e);
	}
	Solution& solve();
};

int main(){
	int n,m;
	scanf("%d%d",&n,&m);
	Solver s(n,m,1);
	for (int i=0; i<m; i++){
		int a,b,c;
		scanf("%d%d%d",&a,&b,&c);
		s.pushEdge(a,b,c);
	}
	Solver::Solution& solution=s.solve();
	printf("%d\n",solution.profitNumb);
	for (int node:solution.nodes){
		printf("%d ",node);
	}
	puts("\n");
	return 0;
}

Solver::Solution& Solver::solve() {
	bool wasChanged=true;
	for (int i=1; i<V && wasChanged; i++){
		wasChanged=false;
		for (Edge e:edges){
			if (d[e.v]>d[e.u]+e.weight) {
				wasChanged=true;
				d[e.v]=d[e.u]+e.weight;
			}
		}
	}
	if (!wasChanged) solution.profitNumb=0;
	else {
		for(Edge e:edges){
			if (d[e.v]>d[e.u]+e.weight){
				solution.profitNumb++;
				solution.nodes.push_back(e.v);
			}
		}
	}
	return solution;
}

