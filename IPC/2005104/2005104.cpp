/*
  Compilation:
    g++ -pthread 2005104.cpp -o a.out

  Usage:
    ./a.out <input_file> <output_file>

  Input:
    The input file should contain the number of standard visitors (N), number of premium visitors(M),
	and the time taken to walk from one point to another (w, x, y, z).

  Output:
    Each visitor's arrival time at the different points is shown in the console.

  Prepared by: Md Hasin Arafat Al Sifat (2005104), Date: 16 November 2024

*/
#include <chrono>
#include <fstream>
#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <random>
#include <unistd.h>
#include <vector>
#include <algorithm>
using namespace std;


// Macro definitions
#define MAX_GALLERY_1 5
#define MAX_GLASS_CORRIDOR 3

//Mutexes and Semaphores
sem_t gallery_1;
sem_t glass_corridor;
pthread_mutex_t step0;
pthread_mutex_t step1;
pthread_mutex_t step2;
pthread_mutex_t entry_lock;
pthread_mutex_t photo_booth;
pthread_mutex_t standard_visitor;
pthread_mutex_t premium_visitor;
pthread_mutex_t output;


//variables
int N,M,w,x,y,z;
int standard_in_booth = 0;
int premiums_in_booth = 0;

//chrono
auto start_time = chrono::high_resolution_clock::now();

//Visitor struct
struct Visitor{
	int id;
	bool is_premium;
	Visitor(int id,bool premium):id(id),is_premium(premium){}
};



void init_semaphore(){
	sem_init(&gallery_1,0,MAX_GALLERY_1);
	sem_init(&glass_corridor,0,MAX_GLASS_CORRIDOR);
	pthread_mutex_init(&step0,0);
	pthread_mutex_init(&step1,0);
	pthread_mutex_init(&step2,0);
	pthread_mutex_init(&entry_lock,0);
	pthread_mutex_init(&photo_booth,0);
	pthread_mutex_init(&premium_visitor,0);
	pthread_mutex_init(&standard_visitor,0);
	pthread_mutex_init(&output,0);
}

long long get_time() {
    auto end_time = chrono::high_resolution_clock::now();
    auto duration = chrono::duration_cast<chrono::milliseconds>(end_time - start_time);
    return duration.count();
}

int get_random_number(double lambda) {
  random_device rd;
  mt19937 generator(rd());
  //double lambda = 10000.234;
  poisson_distribution<int> poissonDist(lambda);
  return poissonDist(generator);
}

void hallway(Visitor& visitor){
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" has arrived at A at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
    sleep(w);
	sleep(get_random_number(w));
	pthread_mutex_lock(&output);
    cout<<"Visitor "<<visitor.id<<" has arrived at B at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
}

void at_step(int step, Visitor& visitor){
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is at step "<<step+1<<" at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
	sleep(1);
}

void at_gallery_1(Visitor& visitor){
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is at C (entered Gallery 1) at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
	sleep(x);
	sleep(get_random_number(1));
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is at D (exiting Gallery 1) at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
}

void at_glass_corridor(Visitor& visitor){
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is at entered Glass Corridor at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
	sleep(get_random_number(1));
}

void at_gallery_2(Visitor& visitor){
	//pthread_mutex_lock(&gallery2);
	pthread_mutex_lock(&output);
    cout<<"Visitor "<<visitor.id<<" is at E (entered Gallery 2) at time "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
	//pthread_mutex_unlock(&gallery2);
	sleep(y);
	sleep(get_random_number(1.5));
}

void at_waiting_area(Visitor& visitor){
	// if(visitor.is_premium){
	// 	premiums_waiting++;
	// }
	//pthread_mutex_lock(&waiting_area);
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is about to enter the photo booth at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
	//sleep(1);
	//pthread_mutex_unlock(&waiting_area);
}

void premium_at_photo_booth(Visitor& visitor){
	pthread_mutex_lock(&premium_visitor);
	premiums_in_booth++;
	if(premiums_in_booth == 1) pthread_mutex_lock(&entry_lock);
	pthread_mutex_unlock(&premium_visitor);

	pthread_mutex_lock(&photo_booth);
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is inside the photo booth at timestamp " <<get_time()<<endl;
	pthread_mutex_unlock(&output);
	sleep(z);
	sleep(get_random_number(1.5));
	pthread_mutex_unlock(&photo_booth);

	pthread_mutex_lock(&premium_visitor);
	premiums_in_booth--;
	if(premiums_in_booth == 0) pthread_mutex_unlock(&entry_lock);
	pthread_mutex_unlock(&premium_visitor);
}

void standard_at_photo_booth(Visitor& visitor){
	pthread_mutex_lock(&entry_lock);

    pthread_mutex_lock(&standard_visitor);
    standard_in_booth++;
    if(standard_in_booth == 1) pthread_mutex_lock(&photo_booth);
    pthread_mutex_unlock(&standard_visitor);

    pthread_mutex_unlock(&entry_lock);
	pthread_mutex_lock(&output);
    cout<<"Visitor "<<visitor.id<<" is inside the photo booth at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
    sleep(z);

    pthread_mutex_lock(&standard_visitor);
    standard_in_booth--;
    if(standard_in_booth == 0) pthread_mutex_unlock(&photo_booth);
    pthread_mutex_unlock(&standard_visitor);
}

void exit_meuseum(Visitor& visitor){
	pthread_mutex_lock(&output);
	cout<<"Visitor "<<visitor.id<<" is exiting the museum at timestamp "<<get_time()<<endl;
	pthread_mutex_unlock(&output);
}

void* visitor_acitivity(void* arg){
	Visitor* visitor = (Visitor*)arg;
	sleep(get_random_number(1.5));
	//arriving at the hallway
	hallway(*visitor);

	//at step 1 
	pthread_mutex_lock(&step0);
	at_step(0, *visitor);

	//at step 2
	pthread_mutex_lock(&step1);
	pthread_mutex_unlock(&step0);
	at_step(1, *visitor);

	//at step 3
	pthread_mutex_lock(&step2);
	pthread_mutex_unlock(&step1);
	at_step(2, *visitor);

	//entering gallery 1
	sem_wait(&gallery_1);
	pthread_mutex_unlock(&step2);
	at_gallery_1(*visitor);

	//entering glass corridor
	sem_wait(&glass_corridor);
	sem_post(&gallery_1);
	at_glass_corridor(*visitor);

	//entering gallery 2
	sem_post(&glass_corridor);
	at_gallery_2(*visitor);

	//waiting for the photo booth
	at_waiting_area(*visitor);

	//at the photo booth
	if(visitor->is_premium){
		premium_at_photo_booth(*visitor);
	}else{
		standard_at_photo_booth(*visitor);
	}

	//exit
	exit_meuseum(*visitor);

	return nullptr;
}

int main(int argc, char *argv[]){
	if (argc != 3) {
		cout << "Usage: ./2005104.out N M w x y z " <<endl;
		return 0;
	}


	ifstream inputFile(argv[1]);
   	streambuf *cinBuffer = std::cin.rdbuf();
  	cin.rdbuf(inputFile.rdbuf()); 

  	ofstream outputFile(argv[2]);
  	streambuf *coutBuffer = std::cout.rdbuf();
  	cout.rdbuf(outputFile.rdbuf()); 

	cin>>N>>M>>w>>x>>y>>z;

	init_semaphore();
	vector<Visitor> visitors;
	vector<pthread_t> visitor_threads;

	for(int i=0;i<N;i++){
		visitors.emplace_back(1001+i,false);
	}

	for(int i=0;i<M;i++){
		visitors.emplace_back(2001+i,true);
	}


	random_device rd;
    mt19937 g(rd());

    shuffle(visitors.begin(), visitors.end(), g);

	for(auto& visitor : visitors){
		pthread_t thread;
		pthread_create(&thread,0,visitor_acitivity,(void*)&visitor);
		visitor_threads.push_back(thread);
		sleep(get_random_number(1.5));
	}

	for(auto& thread : visitor_threads){
		pthread_join(thread,0);
	}

	pthread_mutex_destroy(&step0);
    pthread_mutex_destroy(&step1);
    pthread_mutex_destroy(&step2);
	sem_destroy(&gallery_1);
    sem_destroy(&glass_corridor);

    return 0;
}