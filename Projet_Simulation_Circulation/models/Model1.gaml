
model carrefour

 /*
 * 
 * CONCEPTION ET IMPLÉMENTATION D'UNE SIMULATION, SUR LE PLATE-FORME GAMA, 
 *              DE LA CIRCULATION DANS UN CARREFOUR DE HANOI
*  
*                        Auteur: Mongetro GOINT 
* 
*                      ======== MODELE 1 ======== 
* + Créer un fichier GIS qui représente le réseau de transport dans un carrefour de vôtre choix
    de Hanoi. Puis l'importer au modèle comme l'environment du modèle.
   
  + Créer des agents motos et/ou voitures: taille de agent, la vitesse maximale, la vitesse
    actuelle, la direction de circulation (tourner à droite, à gauche, ou tout droit). Ce sont les
    paramètre qui sont initialisées par hasard. Ces agents ont la capacité de rouler, d'éviter les
    obstacles et autres moyennes de transport.
· 
* + Généger continuelement les moyennes de transport par hasard au 4 rues qui se connectent au
    carrefour. Chaque moyenne de transport peut aller à 1 sur 3 rues restées.
* 
* + Ajouter une parametre pour modifier l'intensité des moyennes des transport dans le modèle:
    Plus l'intensité est grande, plus les agents de moyenne de transport sont nombreux, et
    l'inverse.
* 
 */
 
global {
	
	//global shape files
	file shape_file_lines <- file('../includes/Carrefour/lines.shp');
	file shape_file_enveloppes <- file('../includes/Carrefour/envelopes.shp');
	file shape_file_grounds <- file('../includes/Carrefour/grounds.shp');
	file shape_file_departures <- file('../includes/Carrefour/departures.shp');
	file shape_file_arrivals <- file('../includes/Carrefour/arrivals.shp');

//Attibuts list
	int repulsion_strength min: 2 <- 15 ;
	int nb_vehicule <- 10;
	float min_speed <- 3.0;
	float max_speed <- 8.0;
	int size_of_vehicule <- 20;
	graph the_graph;
	int range_of_vehicules min:1 <- 10; 
	
		
	init {
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
	
	reflex creer_nouveaux_vehicules when:flip(0.8){
		
		// Creation of new vehicule
		create vehicule number: 1{
			set location <- any_location_in( one_of(departure));
				set speed <- min_speed + rnd(max_speed - min_speed);
				set the_departure <- one_of (departure);
				set the_arrival <- one_of (arrival);
				set the_target <- any_location_in(the_arrival);
		}
	}
	
}
entities {
	
//The species list
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
		rgb color <- rgb('gray');
		aspect base {
			draw geometry: shape color: color;
		}
	}
	
	
	species vehicule skills:[moving] {
		rgb color <- rgb('blue');
		departure the_departure <- nil;
		const range type: float <- float(range_of_vehicules);
		arrival the_arrival <- nil;
		int heading <- rnd(350);
		point the_target <- nil;
		
		reflex move when: the_target != nil {
			do goto target: the_target on: the_graph;
			switch the_target {
				match location {do action:die;}
			}
		}
		
		reflex flee_others {
			let close type: vehicule <- one_of (((self neighbours_at range ) of_species vehicule) sort_by (self distance_to each));
			if (close != nil){
				set heading <- (self towards close ) - 160 ;
				let dist <- self distance_to close;
				do move speed: repulsion_strength / dist heading: heading;
			}
		}
		
		aspect base {
			draw shape  color: color size:size_of_vehicule;
		}
	}
}

environment bounds: shape_file_enveloppes ;
	
experiment carrefour_01 type: gui {
	
	//The parameters
	parameter 'Shapefile for the lines:' var: shape_file_lines category: 'GIS' ;
	parameter 'Shapefile for the grounds:' var: shape_file_grounds category: 'GIS' ;
	parameter 'Shapefile for the departures:' var: shape_file_departures category: 'GIS';
	parameter 'Shapefile for the arrivals:' var: shape_file_arrivals category: 'GIS';
	
	parameter 'Number of vehicules :' var:nb_vehicule category:'Vehicule';
	output {
		display carrefour_display refresh_every: 1 {
			
			// Species to display
			species lines aspect: base ;
			species ground aspect: base;
			species departure aspect: base;
			species arrival aspect: base;
			species vehicule aspect: base;
		}
	}
}