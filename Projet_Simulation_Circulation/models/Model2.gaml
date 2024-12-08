model Model3

/*
 * 
 *  CONCEPTION ET IMPLÉMENTATION D'UNE SIMULATION, SUR LE PLATE-FORME GAMA, 
 *                   DE LA CIRCULATION DANS UN CARREFOUR DE HANOI
*  
*                         Auteur: Mongetro GOINT* 
* 
*                       ======== MODELE 2 ========  * 
*   Finir le modèle 1 &
   
  + Créer des agents de feus rouges. Leur couleur change régulièrement avec des intervalles prédéfinies.
     Ces intervalles sont des paramètres changeables.
· 
* + Ajouter un comportement de la moyenne de transport: elle s'arrête quand le leur rouge de
    cette direction est en rouge. Dans le cas du feur vert, elle déplace comme le normal. 
* 
* 
* */


global {
	
//global shape files
	file shape_file_lines <- file('../includes/Carrefour/lines.shp');
	file shape_file_envelopes <- file('../includes/Carrefour/envelopes.shp');
	file shape_file_grounds <- file('../includes/Carrefour/grounds.shp');
	file shape_file_departures <- file('../includes/Carrefour/departures.shp');
	file shape_file_arrivals <- file('../includes/Carrefour/arrivals.shp');
	file shape_file_fireareas <- file('../includes/Carrefour/waiting_area.shp');
	file shape_file_fire <- file('../includes/Carrefour/fire.shp');
	
	//Attibuts list
	int repulsion_strength min: 2 <- 15 ;
	int nb_vehicule <- 10;
	float min_speed <- 3.0;
	float max_speed <- 8.0;
	int size_of_vehicule <- 20;
	graph the_graph;
	int range_of_vehicules min:1 <- 10; 
	//duration for red light
	int time_red <- 60;
	//duration for green light
	int time_green <- 60;
	//duration for yellow light
	int time_yellow <-5;
	list list_areas of:area;
	int cycle_time update: time mod (time_red + time_green + time_yellow);

		
	init {
		create fire from: shape_file_fire;
		create firearea from: shape_file_fireareas;
		create lines from: shape_file_lines;
		set the_graph <- as_edge_graph(list(lines));
		create ground from: shape_file_grounds;
		create departure from: shape_file_departures;
		create arrival from: shape_file_arrivals;
		create vehicule number: nb_vehicule{
			
				set location <- any_location_in( one_of(departure));
				set speed <- min_speed + rnd(max_speed - min_speed);
				set the_departure <- one_of (departure);
				set the_arrival <- one_of (arrival);
				set the_target <- any_location_in(the_arrival);
		}
	}
	// Creation of new vehicule
	reflex creer_nouveaux_vehicules when:flip(0.5){
		create vehicule number: 1{
			set location <- any_location_in( one_of(departure));
				set speed <- min_speed + rnd(max_speed - min_speed);
				set bk_speed <- speed;
				set the_departure <- one_of (departure);
				set the_arrival <- one_of (arrival);
				set the_target <- any_location_in(the_arrival);
		}
	}
	
}
entities {
	
//The species list
	species area {
		rgb color <- rgb('white');
		aspect base{
			draw shape: geometry color:color;
		}		
	}
	
	species fire control:fsm{
		rgb color <- rgb('white');
		state in_red initial:true{
			set color <- rgb('red');
			transition to: in_green when: cycle_time =0;
		}
		state in_green {
			set color <- rgb('green');
			transition to: in_yellow when: cycle_time = time_green;
		}
		state in_yellow {
			set color <- rgb('yellow');
			transition to: in_red when: cycle_time = time_green + time_yellow;
		}
		aspect base {
			draw geometry: shape color: color ;
		}
	}
	
	species firearea control:fsm{
		rgb color <- rgb('gray');
		state have_stop initial:true{
			set color <- rgb('red');
			transition to: allow_go when: cycle_time =0;
		}
		state allow_go {
			set color <- rgb('green');
			transition to: have_stop when: cycle_time = time_green;
		}
		
		aspect base {
			draw geometry: shape color: color ;
		}
	}
	
	species lines  {
		rgb color <- rgb('white') ;
		aspect base {
			draw geometry: shape color: color ;
		}
	}
	
	species ground {
		string type;
		rgb color <- rgb('white');
		aspect base {
			draw geometry: shape color: color;
		}
	}
	
	species departure {
		rgb color <- rgb('green');
		aspect base {
			draw geometry: shape color: color;
		}
	}
	
	species arrival {
		rgb color <- rgb('blue');
		aspect base {
			draw geometry: shape color: color;
		}
	}
	
	species firesignal {
		rgb color <- rgb('black');
		aspect base {
			draw geometry: shape color: color;
		}
	}
	
	species vehicule skills:[moving] {
		bool in_fire_area  update: self.shape intersects one_of(list(firearea));
		rgb color <- rgb('yellow');
		departure the_departure <- nil;
		const range type: float <- float(range_of_vehicules);
		arrival the_arrival <- nil;
		int heading <- rnd(359);
		point the_target <- nil;
		bool is_waiting_red <- false;
		int bk_speed <- 0;
		
		//The reflexs
		reflex move when: the_target != nil {
			do goto target: the_target on: the_graph;
			switch the_target {
				match location {do action:die;}
			}
		}
		reflex flee_others {
			let close type: vehicule <- one_of (((self neighbours_at range ) of_species vehicule) sort_by (self distance_to each));
			if (close != nil){
				set heading <- (self towards close ) - 180 ;
				let dist <- self distance_to close;
				do move speed: max([dist/ repulsion_strength,0]) heading: heading bounds:list_areas;
			}
		}
		
		reflex see_fire when: in_fire_area and !is_waiting_red{
			let nearby_fire type:fire value:first((list(fire) sort_by( self distance_to each)));		
				if nearby_fire.state = 'in_red'{
					set bk_speed <- speed;
					set speed <- 0;
					set is_waiting_red <- true;
				}
		}
		
		reflex check_to_go when: is_waiting_red{
			let nearby_fire type:fire value:first((list(fire) sort_by( self distance_to each)));		
				if nearby_fire.state = 'in_green'{
					set speed <- bk_speed;
					set is_waiting_red <- false;
				}
		}
		
		aspect base {
			draw shape: circle(2) color: color size:size_of_vehicule;
			draw text: string(in_fire_area) at: location + {-3,1.5} color: rgb('red') size: 5.8 ;
		}
	}
}

environment bounds: shape_file_envelopes {
}
	
experiment carrefour_02 type: gui {
	
//The parameters
	parameter 'Shapefile for the lines:' var: shape_file_lines category: 'GIS' ;
	parameter 'Shapefile for the grounds:' var: shape_file_grounds category: 'GIS' ;
	parameter 'Shapefile for the departures:' var: shape_file_departures category: 'GIS';
	parameter 'Shapefile for the arrivals:' var: shape_file_arrivals category: 'GIS';
	parameter 'Shapefile for the fire:' var: shape_file_fire category: 'GIS';
	parameter 'Shapefile for the fire areas:' var: shape_file_fireareas category: 'GIS';
	
	parameter 'Number of vehicules :' var:nb_vehicule category:'Vehicule';
	output {
		display carrefour_display refresh_every: 1 {
			
		// Species to display
			species firearea aspect:base;
			species lines aspect: base ;
			species ground aspect: base;
			species departure aspect: base;
			species arrival aspect: base;
			species vehicule aspect: base;
			species fire aspect: base;
		}
	}
}