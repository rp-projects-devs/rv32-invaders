####################################################################################################
#                                  CAPTURE SANS AFFICHAGE (prefixe T_)                             #
####################################################################################################
#
# Fait tourner une partie complete sans Bitmap Display ni clavier, en ligne de commande :
#	java -jar rars.jar nc tests/capture.s > capture.txt
#
# - Le clavier est remplace par deux mots en memoire : keyboard_status_address et
#   keyboard_data_address sont redirigees vers T_faux_statut et T_fausse_donnee.
# - Un pilote automatique tres simple joue a la place du joueur : il se place sous l'envahisseur
#   vivant le plus proche et tire.
# - Apres chaque frame, le buffer est ecrit dans la console (une ligne commencant par "#F" suivie
#   des couleurs des units en hexadecimal). tools/render_capture.py transforme ce texte en GIF.
#
# Ce programme sert de test de bout en bout (la partie doit se terminer sans erreur) et a produire
# l'animation de demonstration du README.

.data

T_faux_statut : .word 0 #Remplace le registre de statut du clavier
T_fausse_donnee : .word 0 #Remplace le registre de donnee du clavier
T_frames_maximum : .word 4000 #Securite : nombre maximum de frames simulees
T_graine : .word 123 #Graine fixe pour que la capture soit reproductible
T_texte_frame : .asciz "#F"
T_texte_saut_ligne : .asciz "\n"

.text
	j T_main

.include "../src/config.s"
.include "../src/affichage.s"
.include "../src/son.s"
.include "../src/donnees.s"
.include "../src/mouvement.s"
.include "../src/collisions.s"
.include "../src/partie.s"

.text

#Resume :
#	Choisit la touche que presserait le pilote automatique et l'ecrit dans le faux clavier
#Preconditions : La partie est initialisee
#Entrees : //
#Sorties : //
T_pilote :
	#Prologue
	addi sp,sp,-20
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	sw s3,16(sp)
	#Fin prologue
	lw t0,J_adresse
	lw s0,0(t0) #s0 : Abscisse du joueur
	lw t0,player_width
	srli t0,t0,1
	add s0,s0,t0 #s0 : Abscisse du milieu du joueur
	lw t0,E_adresse
	addi t1,t0,8 #t1 : Adresse de l'envahisseur courant
	lw t2,invaders_number #t2 : Compteur d'envahisseurs
	lw t3,invaders_alive_status #t3 : Statut d'un envahisseur vivant
	lw t4,invaders_width
	srli t4,t4,1 #t4 : Demi-largeur d'un envahisseur
	li s1,-1 #s1 : Abscisse du milieu de la cible (-1 : pas de cible)
	li s2,1000 #s2 : Plus petite distance trouvee
	T_pilote_recherche :
		beqz t2,T_pilote_decision #Si tous les envahisseurs sont traites, la cible est connue
		lw t5,8(t1) #t5 : Statut vital de l'envahisseur
		bne t5,t3,T_pilote_suivant #Si l'envahisseur est mort, il n'est pas une cible
		lw t5,0(t1)
		add t5,t5,t4 #t5 : Abscisse du milieu de l'envahisseur
		sub t6,t5,s0 #t6 : Ecart avec le joueur
		bgez t6,T_pilote_distance
		neg t6,t6 #t6 : Valeur absolue de l'ecart
		T_pilote_distance :
			bge t6,s2,T_pilote_suivant #Si l'envahisseur n'est pas plus proche, on garde la cible
			mv s2,t6 #s2 : Nouvelle plus petite distance
			mv s1,t5 #s1 : Nouvelle cible
	T_pilote_suivant :
		addi t1,t1,12 #t1 : Envahisseur suivant
		addi t2,t2,-1 #t2 : Decremente le compteur d'envahisseurs
		j T_pilote_recherche
	T_pilote_decision :
		li s3,1 #s3 : Une touche est pressee
		#Esquive : si un missile ennemi arrive au-dessus du joueur, s'ecarte vers le centre
		lw t1,M_adresse #t1 : Adresse du missile courant
		lw t2,missiles_maximum #t2 : Compteur de missiles
		lw t3,J_adresse
		lw t3,0(t3) #t3 : Abscisse gauche du joueur
		lw t4,player_width
		add t4,t4,t3 #t4 : Abscisse droite du joueur (exclue)
		addi t3,t3,-1 #t3 : Marge d'une case a gauche
		T_pilote_danger :
			beqz t2,T_pilote_viser #Si aucun missile n'est dangereux, vise la cible
			lw t5,12(t1) #t5 : Statut d'existence du missile
			beqz t5,T_pilote_danger_suivant #Si le missile n'existe pas, il n'est pas dangereux
			lw t5,8(t1) #t5 : Direction du missile
			bnez t5,T_pilote_danger_suivant #Si le missile monte, il n'est pas dangereux
			lw t5,4(t1) #t5 : Ordonnee du missile
			li t6,20
			blt t5,t6,T_pilote_danger_suivant #Si le missile est encore loin, il n'est pas dangereux
			lw t5,0(t1) #t5 : Abscisse du missile
			blt t5,t3,T_pilote_danger_suivant #Si le missile passe a gauche, il n'est pas dangereux
			bgt t5,t4,T_pilote_danger_suivant #Si le missile passe a droite, il n'est pas dangereux
			li t6,16
			blt s0,t6,T_pilote_droite #Danger : si le joueur est a gauche du centre, fuit a droite
			j T_pilote_gauche #Sinon, fuit a gauche
		T_pilote_danger_suivant :
			addi t1,t1,16 #t1 : Missile suivant
			addi t2,t2,-1 #t2 : Decremente le compteur de missiles
			j T_pilote_danger
	T_pilote_viser :
		bltz s1,T_pilote_aucune #Sans cible, aucune touche
		blt s0,s1,T_pilote_droite #Si la cible est a droite, va a droite
		bgt s0,s1,T_pilote_gauche #Si la cible est a gauche, va a gauche
		lw t0,key_shoot #Sinon, tire
		j T_pilote_ecrire
	T_pilote_droite :
		lw t0,key_right
		j T_pilote_ecrire
	T_pilote_gauche :
		lw t0,key_left
		j T_pilote_ecrire
	T_pilote_aucune :
		li s3,0
		li t0,0
	T_pilote_ecrire :
		sw t0,T_fausse_donnee,t1 #Ecrit le code de la touche
		sw s3,T_faux_statut,t1 #Ecrit le statut du clavier
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	lw s1,8(sp)
	lw s2,12(sp)
	lw s3,16(sp)
	addi sp,sp,20
	jr ra
	#Fin epilogue

#Resume :
#	Ecrit le contenu du buffer dans la console sur une seule ligne
#Preconditions : Le buffer existe
#Entrees : //
#Sorties : //
T_ecrire_buffer :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	#Fin prologue
	la a0,T_texte_frame
	li a7,4
	ecall
	lw s0,I_buff #s0 : Adresse mouvante dans le buffer
	lw s1,I_nb_unit #s1 : Compteur de units
	T_ecrire_buffer_boucle :
		beqz s1,T_ecrire_buffer_fin #Si tous les units sont ecrits, fin de la fonction
		lw a0,0(s0) #a0 : Couleur du unit
		li a7,34
		ecall #Ecrit la couleur en hexadecimal
		addi s0,s0,4 #s0 : Unit suivant
		addi s1,s1,-1 #s1 : Decremente le compteur de units
		j T_ecrire_buffer_boucle
	#Epilogue
	T_ecrire_buffer_fin :
		la a0,T_texte_saut_ligne
		li a7,4
		ecall
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		addi sp,sp,12
		jr ra
	#Fin epilogue

T_main :
	sw zero,sound_enabled,t0 #Pas de son en ligne de commande
	la t1,T_faux_statut
	sw t1,keyboard_status_address,t0 #Redirige le statut du clavier
	la t1,T_fausse_donnee
	sw t1,keyboard_data_address,t0 #Redirige la donnee du clavier
	lw a0,T_graine
	jal P_initialiser
	li s0,0 #s0 : Nombre de frames simulees
	lw s1,T_frames_maximum #s1 : Nombre maximum de frames
	T_main_boucle :
		jal T_pilote #Choisit la touche de la frame
		jal P_frame
		mv s2,a0 #s2 : Etat de la partie
		jal T_ecrire_buffer
		addi s0,s0,1 #s0 : Une frame de plus
		lw t0,game_running_status
		bne s2,t0,T_main_fin #Si la partie est terminee, fin de la simulation
		blt s0,s1,T_main_boucle #Tant que la limite n'est pas atteinte, continue
	T_main_fin :
		mv a0,s2
		jal P_fin
		jal T_ecrire_buffer #Derniere image, avec le cadre de fin
		li a7,10
		ecall
