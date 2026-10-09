####################################################################################################
#                                  TESTS UNITAIRES (prefixe T_)                                    #
####################################################################################################
#
# Tests des fonctions du jeu, sans affichage, en ligne de commande :
#	java -jar rars.jar nc tests/test_unitaires.s
#
# Chaque verification affiche "[OK]" ou "[ECHEC]" suivi de son nom. Le programme se termine avec
# le code de sortie 0 si tout passe, 1 sinon (utilise par tools/run_tests.sh et l'integration
# continue).

.data

T_nb_echecs : .word 0 #Nombre de verifications echouees
T_texte_ok : .asciz "[OK]     "
T_texte_echec : .asciz "[ECHEC]  "
T_texte_obtenu : .asciz "  (obtenu : "
T_texte_attendu : .asciz ", attendu : "
T_texte_parenthese : .asciz ")"
T_texte_saut_ligne : .asciz "\n"
T_texte_bilan_ok : .asciz "\nTous les tests passent.\n"
T_texte_bilan_echec : .asciz "\nNombre de tests en echec : "

T_nom_chevauchement : .asciz "C_intersecte_rectangles : rectangles qui se chevauchent"
T_nom_contact : .asciz "C_intersecte_rectangles : rectangles colles sans chevauchement"
T_nom_inclusion : .asciz "C_intersecte_rectangles : rectangle inclus dans l'autre"
T_nom_separes : .asciz "C_intersecte_rectangles : rectangles separes verticalement"
T_nom_xy_addr_x : .asciz "I_xy_to_addr puis I_addr_to_xy : abscisse retrouvee"
T_nom_xy_addr_y : .asciz "I_xy_to_addr puis I_addr_to_xy : ordonnee retrouvee"
T_nom_murs_y : .asciz "O_creer : murs places aux 4/5 de la hauteur"
T_nom_murs_x : .asciz "O_creer : abscisse du deuxieme mur"
T_nom_grille_x : .asciz "E_creer : abscisse du premier envahisseur de la deuxieme ligne"
T_nom_grille_y : .asciz "E_creer : ordonnee du premier envahisseur de la deuxieme ligne"
T_nom_periode : .asciz "P_periode_envahisseurs : periode avec tous les envahisseurs"
T_nom_missiles_ajout : .asciz "M_ajouter_missile : ajout possible tant qu'il reste de la place"
T_nom_missiles_plein : .asciz "M_ajouter_missile : refus quand la structure est pleine"
T_nom_demi_tour : .asciz "E_deplacer : demi-tour et descente au bord droit"
T_nom_collision_points : .asciz "C_collision : points gagnes en touchant un envahisseur"
T_nom_collision_vivants : .asciz "C_collision : nombre d'envahisseurs en vie decremente"
T_nom_collision_missile : .asciz "C_collision : le missile disparait apres l'impact"
T_nom_collision_mur : .asciz "C_collision : un mur touche perd de la resistance"
T_nom_collision_joueur : .asciz "C_collision : le joueur touche perd une vie"

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
#	Compare une valeur obtenue a la valeur attendue et affiche le resultat de la verification
#Preconditions : //
#Entrees :
#	a0 : Valeur obtenue
#	a1 : Valeur attendue
#	a2 : Adresse du nom de la verification
#Sorties : //
T_verifier :
	#Prologue
	addi sp,sp,-16
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	sw s2,12(sp)
	#Fin prologue
	mv s0,a0 #s0 : Valeur obtenue
	mv s1,a1 #s1 : Valeur attendue
	mv s2,a2 #s2 : Nom de la verification
	bne s0,s1,T_verifier_echec #Si les valeurs different, la verification echoue
	la a0,T_texte_ok
	li a7,4
	ecall
	mv a0,s2
	ecall #Affiche le nom
	j T_verifier_fin
	T_verifier_echec :
		lw t0,T_nb_echecs
		addi t0,t0,1 #t0 : Un echec de plus
		sw t0,T_nb_echecs,t1
		la a0,T_texte_echec
		li a7,4
		ecall
		mv a0,s2
		ecall #Affiche le nom
		la a0,T_texte_obtenu
		ecall
		mv a0,s0
		li a7,1
		ecall #Affiche la valeur obtenue
		la a0,T_texte_attendu
		li a7,4
		ecall
		mv a0,s1
		li a7,1
		ecall #Affiche la valeur attendue
		la a0,T_texte_parenthese
		li a7,4
		ecall
	#Epilogue
	T_verifier_fin :
		la a0,T_texte_saut_ligne
		li a7,4
		ecall
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		lw s2,12(sp)
		addi sp,sp,16
		jr ra
	#Fin epilogue

T_main :
	sw zero,sound_enabled,t0 #Pas de son en ligne de commande

	#### C_intersecte_rectangles ####
	li a0,0
	li a1,0
	li a2,4
	li a3,4
	li a4,2
	li a5,2
	li a6,4
	li a7,4
	jal C_intersecte_rectangles #(0,0,4,4) et (2,2,4,4)
	li a1,1
	la a2,T_nom_chevauchement
	jal T_verifier

	li a0,0
	li a1,0
	li a2,4
	li a3,4
	li a4,4
	li a5,0
	li a6,4
	li a7,4
	jal C_intersecte_rectangles #(0,0,4,4) et (4,0,4,4) : bords colles
	li a1,0
	la a2,T_nom_contact
	jal T_verifier

	li a0,0
	li a1,0
	li a2,10
	li a3,10
	li a4,3
	li a5,3
	li a6,1
	li a7,2
	jal C_intersecte_rectangles #(0,0,10,10) contient (3,3,1,2)
	li a1,1
	la a2,T_nom_inclusion
	jal T_verifier

	li a0,5
	li a1,0
	li a2,3
	li a3,2
	li a4,5
	li a5,6
	li a6,3
	li a7,2
	jal C_intersecte_rectangles #(5,0,3,2) et (5,6,3,2)
	li a1,0
	la a2,T_nom_separes
	jal T_verifier

	#### Initialisation d'une partie ####
	li a0,1
	jal P_initialiser

	#### I_xy_to_addr / I_addr_to_xy ####
	li a0,7
	li a1,12
	jal I_xy_to_addr
	jal I_addr_to_xy
	mv s0,a1 #s0 : Ordonnee retrouvee
	li a1,7
	la a2,T_nom_xy_addr_x
	jal T_verifier
	mv a0,s0
	li a1,12
	la a2,T_nom_xy_addr_y
	jal T_verifier

	#### O_creer ####
	lw a0,walls_y_position
	lw t0,I_hauteur
	li t1,5
	div t0,t0,t1
	slli a1,t0,2 #a1 : (hauteur / 5) * 4
	la a2,T_nom_murs_y
	jal T_verifier
	lw t0,O_adresse
	lw a0,8(t0) #a0 : Abscisse du deuxieme mur
	lw t0,walls_x_margin
	lw t1,walls_x_spacing
	lw t2,walls_width
	add a1,t0,t1
	add a1,a1,t2 #a1 : Marge + espacement + largeur
	la a2,T_nom_murs_x
	jal T_verifier

	#### E_creer ####
	lw s0,E_adresse
	lw t0,invaders_per_ligne
	li t1,12
	mul t0,t0,t1
	addi t0,t0,8
	add s1,s0,t0 #s1 : Adresse du premier envahisseur de la deuxieme ligne
	lw a0,0(s1)
	lw a1,invaders_x_margin
	la a2,T_nom_grille_x
	jal T_verifier
	lw a0,4(s1)
	lw t0,invaders_y_margin
	lw t1,invaders_height
	lw t2,invaders_y_spacing
	add a1,t0,t1
	add a1,a1,t2 #a1 : Marge + hauteur + espacement
	la a2,T_nom_grille_y
	jal T_verifier

	#### P_periode_envahisseurs ####
	lw a0,E_adresse
	jal P_periode_envahisseurs
	lw t0,invaders_number
	lw t1,invaders_speed_divisor
	div t0,t0,t1
	lw t1,invaders_min_period
	add a1,t0,t1
	la a2,T_nom_periode
	jal T_verifier

	#### M_ajouter_missile ####
	lw s0,missiles_maximum #s0 : Nombre de missiles a ajouter
	li s1,1 #s1 : 1 tant que tous les ajouts ont reussi
	T_main_remplissage :
		beqz s0,T_main_remplissage_fin
		lw a0,M_adresse
		li a1,0
		li a2,10
		lw a3,missiles_direction_up
		jal M_ajouter_missile
		and s1,s1,a0 #s1 : Reste a 1 si l'ajout a reussi
		addi s0,s0,-1
		j T_main_remplissage
	T_main_remplissage_fin :
		mv a0,s1
		li a1,1
		la a2,T_nom_missiles_ajout
		jal T_verifier
		lw a0,M_adresse
		li a1,0
		li a2,10
		lw a3,missiles_direction_up
		jal M_ajouter_missile #Un missile de trop
		li a1,0
		la a2,T_nom_missiles_plein
		jal T_verifier

	#### E_deplacer ####
	#Le groupe se deplace vers la droite jusqu'au bord, puis descend : on deplace assez de fois
	#pour atteindre le bord et on verifie que la direction a change et que la ligne est descendue
	lw s0,E_adresse
	lw s1,12(s0) #s1 : Ordonnee initiale du premier envahisseur
	lw s2,I_largeur #s2 : Nombre de deplacements, suffisant pour atteindre le bord
	T_main_deplacements :
		beqz s2,T_main_deplacements_fin
		lw t0,0(s0) #t0 : Direction du groupe
		lw t1,invaders_direction_left
		beq t0,t1,T_main_deplacements_fin #Des que le groupe repart a gauche, on arrete
		mv a0,s0
		jal E_deplacer
		addi s2,s2,-1
		j T_main_deplacements
	T_main_deplacements_fin :
		lw a0,12(s0) #a0 : Ordonnee du premier envahisseur apres le demi-tour
		lw t0,invaders_y_movement
		add a1,s1,t0 #a1 : Ordonnee initiale + descente
		la a2,T_nom_demi_tour
		jal T_verifier

	#### C_collision ####
	#Vide les missiles, puis place un missile montant sur le premier envahisseur
	jal M_creer
	sw a0,M_adresse,t0 #Nouvelle structure missiles vide
	lw s0,E_adresse
	lw a0,M_adresse
	lw a1,8(s0) #a1 : Abscisse du premier envahisseur
	lw a2,12(s0) #a2 : Ordonnee du premier envahisseur
	lw a3,missiles_direction_up
	jal M_ajouter_missile
	lw a0,M_adresse
	lw a1,O_adresse
	lw a2,E_adresse
	lw a3,J_adresse
	jal C_collision
	lw a1,invaders_points
	la a2,T_nom_collision_points
	jal T_verifier
	lw a0,4(s0) #a0 : Envahisseurs en vie
	lw a1,invaders_number
	addi a1,a1,-1
	la a2,T_nom_collision_vivants
	jal T_verifier
	lw t0,M_adresse
	lw a0,12(t0) #a0 : Statut du missile
	lw a1,missiles_not_exist_status
	la a2,T_nom_collision_missile
	jal T_verifier

	#Missile descendant sur le premier mur
	lw s1,O_adresse
	lw a0,M_adresse
	lw a1,0(s1) #a1 : Abscisse du premier mur
	lw a2,walls_y_position #a2 : Ordonnee des murs
	lw a3,missiles_direction_down
	jal M_ajouter_missile
	lw a0,M_adresse
	lw a1,O_adresse
	lw a2,E_adresse
	lw a3,J_adresse
	jal C_collision
	lw a0,4(s1) #a0 : Resistance du premier mur
	lw a1,walls_resistance
	addi a1,a1,-1
	la a2,T_nom_collision_mur
	jal T_verifier

	#Missile descendant sur le joueur
	lw s1,J_adresse
	lw a0,M_adresse
	lw a1,0(s1) #a1 : Abscisse du joueur
	lw t0,I_hauteur
	lw t1,player_height
	sub a2,t0,t1 #a2 : Ordonnee du joueur
	lw a3,missiles_direction_down
	jal M_ajouter_missile
	lw a0,M_adresse
	lw a1,O_adresse
	lw a2,E_adresse
	lw a3,J_adresse
	jal C_collision
	lw a0,4(s1) #a0 : Vies du joueur
	lw a1,player_lives
	addi a1,a1,-1
	la a2,T_nom_collision_joueur
	jal T_verifier

	#### Bilan ####
	lw t0,T_nb_echecs
	bnez t0,T_main_echec
	la a0,T_texte_bilan_ok
	li a7,4
	ecall
	li a0,0
	li a7,93
	ecall #Fin avec le code 0
	T_main_echec :
		la a0,T_texte_bilan_echec
		li a7,4
		ecall
		lw a0,T_nb_echecs
		li a7,1
		ecall
		la a0,T_texte_saut_ligne
		li a7,4
		ecall
		li a0,1
		li a7,93
		ecall #Fin avec le code 1
