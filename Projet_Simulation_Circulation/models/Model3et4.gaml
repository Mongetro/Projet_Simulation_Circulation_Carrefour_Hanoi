 model carrefour
 
/*
 * 
 * CONCEPTION ET IMPLÉMENTATION D'UNE SIMULATION, SUR LE PLATE-FORME GAMA, 
 *              DE LA CIRCULATION DANS UN CARREFOUR DE HANOI
*  
*                        Auteur: Mongetro GOINT 
* 
*                      ======== MODELE 3 & 4 ========
 *   Modèle 3:
    Finir le modèle 2, puis ajouter:
  + Calculer le le temps d'atend moyenne des gens qui passent le carrefour, et l'afficher sur un chart.
  + Calculer le nombre des gens qui sont passés le carrefour pendant l'intervale précédente de
    feur vert de la même direction, et afficher sur un chart les données des 4 directions du
    carrefour.
    * 
     Modèle 4:
    Finir le modèle 3, puis ajouter:
  + Le feur rouge est maintenant dynamique: la durée vert de feur rouge (d'une direction) est
    relativement au nombre des gens passés le carrefour pendant l'intervale de feur vert
    précédente. Appliquer cette règle dans le modèle.
  + Lancer la simulation les modèles 3 et 4 en plusieurs fois en calculant deux paramètres
    sorties comme celles dans le modèle 3: comparer et analyser les différences entre les deux
    paramètres à partir de deux modèles.
* 
* 
 */

 
 
 global {
	//global shape file
	file shape_file_line <- file('../includes/Carrefour1/line.shp');
	file shape_file_bounds <- file('../includes/Carrefour1/bounds.shp');
	file shape_file_grounds <- file('../includes/Carrefour1/grounds.shp');
	file shape_file_departures <- file('../includes/Carrefour/departures.shp');
	file shape_file_arrivals <- file('../includes/Carrefour/arrivals.shp');
	file shape_file_waiting_area <- file('../includes/Carrefour1/waiting_area.shp');
	file shape_file_traffic_light <- file('../includes/Carrefour1/traffic_light.shp');

//Attibuts list
	int repulsion_strength min: 2 <- 15 ;
	int nb_vehicule <- 10;
	float min_speed <- 3.0;
	float max_speed <- 8.0;
	int min_size_of_vehicle <- 5;
	int max_size_of_vehicle <- 20;
	graph the_graph;
	int range_of_vehicules min:2 <- 10;
	
	const standar_value type:int <- 30;
	int time_start_1 <- 0;
	int time_start_2 <- standar_value;
	int time_start_3 <- 0;
	int time_start_4 <- standar_value;

	int time_green_1 <- int(standar_value * 24/25);
	int time_green_2 <- int(standar_value * 24/25);
	int time_green_3 <- int(standar_value * 24/25);
	int time_green_4 <- int(standar_value * 24/25);
	
	int time_yellow_default <- int(standar_value / 25);
	
	
	int time_red_1 <- standar_value;
	int time_red_2 <- standar_value;
	int time_red_3 <- standar_value;
	int time_red_4 <- standar_value;
	
	list list_time_start <- [time_start_1, time_start_2, time_start_3, time_start_4];
	list list_time_green <- [time_green_1, time_green_2, time_green_3, time_green_4];
	list list_time_yellow <-[time_yellow_default, time_yellow_default, time_yellow_default, time_yellow_default];
	list list_time_red <-   [time_red_1,   time_red_2,   time_red_3,   time_red_4];
	
	list list_wa <- waiting_area as list;
	init {
		create waiting_area		from: shape_file_waiting_area;
		create lines 			from: shape_file_line;
		set the_graph <- as_edge_graph(list(lines));
		create ground 			from: shape_file_grounds;
		create departure 	from: shape_file_departures;
		create arrival	from: shape_file_arrivals;
		create traffic_light 	from: shape_file_traffic_light
				with:[id_light::read('id')]{
					set time_start <- list_time_start at id_light ;
					set time_green <- list_time_green at id_light ;
					set time_red   <- list_time_red   at id_light ;
					set time_yellow <- list_time_yellow at id_light ;
					set total_time <- time_red + time_green + time_yellow;
				}
	// Creation of new vehicule
		create vehicle number: nb_vehicule{
			set location <- any_location_in( one_of(departure));
			set speed <- min_speed + rnd(max_speed - min_speed);
			set the_departure <- one_of (departure);
			set the_arrival <- one_of (arrival);
			set the_target <- any_location_in(the_arrival);
			set is_waiting_light <- false;
		}
	}
// Vehicule reflex when created
	reflex create_vehicles when:flip(0.5){
		create vehicle number: 1{
			set location <- any_location_in( one_of(departure));
			set speed <- min_speed + rnd(max_speed - min_speed);
			set speed_backup <- speed;
			set the_departure <- one_of (departure);
			set the_arrival <- one_of (arrival);
			set the_target <- any_location_in(the_arrival);
			set is_waiting_light <- false;
		}
	}
	
}
entities {
	
//The species list
	species traffic_light control:fsm{
		int id_light <- 0;
		int time_start <- list_time_start at id_light;
		int time_red <- list_time_red at id_light;
		int time_green <- list_time_green at id_light;
		int time_yellow <-list_time_yellow at id_light;
		int total_time <- time_red + time_green + time_yellow;
		int cycle_time update:int((time - time_start >= 0)?
			(time - time_start) mod (total_time)
			:(total_time - (time_start - time)));
		 
		rgb color <- rgb('red');
		
		state startup initial:true{
			transition to: in_red when: cycle_time >= time_green + time_yellow and cycle_time < total_time;
			transition to: in_green when: cycle_time >= 0 and cycle_time < time_green;
			transition to: in_yellow when: cycle_time >= time_green and cycle_time < time_green + time_yellow;
		}
		
		state in_green {
			set color <- rgb('green');
			transition to: in_yellow when: cycle_time = time_green;
		}
		
		state in_yellow {
			set color <- rgb('yellow');
			transition to: in_red when: cycle_time = time_green + time_yellow;
		}
		
		state in_red {
			set color <- rgb('red');
			transition to: in_green when: cycle_time =0;
		}
		
		aspect base {
			draw geometry: shape color: color ;
			draw text: string(cycle_time) at: location + {-3,1.5} color: rgb('black') size: 10.8 ;
			
		}
	}
	
	species waiting_area {
		rgb color <- rgb('gray');
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
	
	species vehicle skills:[moving] {
		int size <- 10;
		rgb color <- rgb('yellow');
		const range type: float <- float(range_of_vehicules);
		float speed <- rnd(max_speed - min_speed)+ min_speed;
		float speed_backup <- speed;
		departure the_departure <- nil;
		arrival the_arrival <- nil;
		point the_target <- nil;
		bool in_waiting_area  update: self.shape intersects one_of(list(waiting_area));
		bool is_waiting_light ;
		bool is_polite <- false;		
		
		
		reflex goto_target when: !is_waiting_light{
			do action: goto_target; 
		}
		
		action goto_target {
			do goto target: the_target on: the_graph;
			switch the_target {
				match location {do action:die;}
			}
		}
		
		reflex elbow {
			let close type: vehicle <- one_of (((self neighbours_at range ) of_species vehicle) sort_by (self distance_to each));
			if (close != nil){
				set heading <- (self towards close ) - 180 ;
				let dist <- self distance_to close;
				do move speed: max([dist/ repulsion_strength,0]) heading: heading ;
			}
		}
		
		
		reflex focus_on_light when: in_waiting_area and !is_waiting_light{
			let nearby_light type:traffic_light value:first((list(traffic_light) sort_by( self distance_to each)));		
				if nearby_light.state = 'in_red' or nearby_light.state = 'in_yellow'{
					set speed_backup <- speed;
					set speed <- 0;
					set is_waiting_light <- true;
				}
		}
		
		reflex check_to_go when: is_waiting_light{
			let nearby_light type:traffic_light value:first((list(traffic_light) sort_by( self distance_to each)));		
				if nearby_light.state = 'in_green'{
					set speed <- speed_backup;
					set is_waiting_light <- false;
				}
		}
		
		reflex check_if_in_wa {
			loop wa over: list_wa{
				if self.shape overlaps wa.shape{
					set in_waiting_area <- true;
				}
			}	
		}
		
		aspect base {
			draw shape: circle(3.5) color: color size:size;
			draw text: string(is_waiting_light) at: location + {-3,1.5} color: rgb('red') size: 5.8 ;
		}
	}
}

environment bounds: shape_file_bounds ;
	
experiment carrefour_03 type: gui {
	
//The parameters
	parameter 'Shapefile for the lines:' var: shape_file_line category: 'GIS' ;
	parameter 'Shapefile for the grounds:' var: shape_file_grounds category: 'GIS' ;
	parameter 'Shapefile for the departures:' var: shape_file_departures category: 'GIS';
	parameter 'Shapefile for the arrivals:' var: shape_file_arrivals category: 'GIS';
	parameter 'Shapefile for the fire:' var: shape_file_traffic_light category: 'GIS';
	parameter 'Shapefile for the fire areas:' var: shape_file_waiting_area category: 'GIS';
	
	parameter 'Number of vehicules :' var:nb_vehicule category:'Vehicule';
	
	output {
		
	// Species to display
		display carrefour_display refresh_every: 1 {
			species waiting_area aspect:base;
			species ground 	aspect:base;
			species lines 		aspect:base;
			species departure aspect: base;
			species arrival aspect: base;
			species vehicle 	aspect: base;
			species traffic_light aspect:base;
			
		}
	}
}
