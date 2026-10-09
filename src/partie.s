####################################################################################################
#                                       PARTIE (prefixe P_)                                        #
####################################################################################################
#
# Orchestration d'une partie : initialisation, deroulement d'une frame, fin de partie.
# P_frame ne fait aucune attente et ne touche pas a l'image affichee : c'est l'appelant (main.s)
# qui recopie le buffer et regle la vitesse. Cela permet aussi de piloter le jeu depuis un programme
# de test, sans affichage (voir tests/capture.s).
#
# Depend de : tous les autres modules

.data

J_adresse : .word 0 #Adresse de la structure joueur
M_adresse : .word 0 #Adresse de la structure missiles
E_adresse : .word 0 #Adresse de la structure envahisseurs
O_adresse : .word 0 #Adresse de la structure obstacles
P_score : .word 0 #Score de la partie
P_compteur_frame : .word 0 #Nombre de frames ecoulees depuis le debut de la partie

P_texte_titre : .asciz "\n===== RV32 INVADERS =====\nCommandes (dans le Keyboard and Display MMIO Simulator) :\n  i : gauche   p : droite   o : tir   x : quitter\n\n"
P_texte_score : .asciz "Score : "
P_texte_vies : .asciz "   |   Vies : "
P_texte_victoire : .asciz "\nVICTOIRE ! Tous les envahisseurs sont detruits.\n"
P_texte_defaite : .asciz "\nDEFAITE... La Terre est envahie.\n"
P_texte_abandon : .asciz "\nPartie abandonnee.\n"
P_texte_score_final : .asciz "Score final : "
P_texte_saut_ligne : .asciz "\n"

P_couleur_victoire : .word 0x0033ff66 #Couleur du cadre en cas de victoire
P_couleur_defaite : .word 0x00ff2222 #Couleur du cadre en cas de defaite
P_couleur_abandon : .word 0x00808080 #Couleur du cadre en cas d'abandon

.text

#Resume :
#	Initialise une partie : alloue les images et toutes les structures, remet le score a zero,
#	initialise le generateur aleatoire et affiche les commandes dans la console.
#	I_visu est alloue en premier pour se trouver au debut du tas (0x10040000), l'adresse lue par le
#	Bitmap Display.
#Preconditions : Aucune allocation dans le tas n'a ete faite auparavant
#Entrees :
#	a0 : Graine du generateur aleatoire
#Sorties : //
P_initialiser :
	#Prologue
	addi sp,sp,-8
	sw ra,0(sp)
	sw s0,4(sp)
	#Fin prologue
	mv s0,a0 #s0 : Graine du generateur aleatoire
	jal I_creer
	sw a0,I_visu,t0 #Alloue l'image affichee
	jal I_effacer
	jal I_creer
	sw a0,I_buff,t0 #Alloue le buffer
	jal I_effacer
	jal J_creer
	sw a0,J_adresse,t0 #Cree le joueur
	jal M_creer
	sw a0,M_adresse,t0 #Cree les missiles
	jal O_creer
	sw a0,O_adresse,t0 #Cree les murs
	jal E_creer
	sw a0,E_adresse,t0 #Cree les envahisseurs
	sw zero,P_score,t0 #Remet le score a zero
	sw zero,P_compteur_frame,t0 #Remet le compteur de frames a zero
	lw a0,M_rng_id #a0 : Identifiant du generateur
	mv a1,s0 #a1 : Graine
	li a7,40
	ecall #Initialise le generateur aleatoire
	la a0,P_texte_titre
	li a7,4
	ecall #Affiche le titre et les commandes
	jal P_afficher_statut
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	addi sp,sp,8
	jr ra
	#Fin epilogue

#Resume :
#	Affiche le score et le nombre de vies dans la console
#Preconditions : La partie est initialisee
#Entrees : //
#Sorties : //
P_afficher_statut :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	la a0,P_texte_score
	li a7,4
	ecall
	lw a0,P_score
	li a7,1
	ecall #Affiche le score
	la a0,P_texte_vies
	li a7,4
	ecall
	lw t0,J_adresse
	lw a0,4(t0)
	li a7,1
	ecall #Affiche le nombre de vies
	la a0,P_texte_saut_ligne
	li a7,4
	ecall
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Calcule le nombre de frames entre deux deplacements des envahisseurs. Moins il reste
#	d'envahisseurs, plus ils vont vite : periode = min_period + envahisseurs en vie / speed_divisor
#Preconditions : La structure envahisseurs existe
#Entrees :
#	a0 : Adresse de la structure envahisseurs
#Sorties :
#	a0 : Periode de deplacement en frames
P_periode_envahisseurs :
	#Prologue
	addi sp,sp,-4
	sw ra,0(sp)
	#Fin prologue
	lw t0,4(a0) #t0 : Nombre d'envahisseurs en vie
	lw t1,invaders_speed_divisor
	div t0,t0,t1 #t0 : Envahisseurs en vie / diviseur
	lw t1,invaders_min_period
	add a0,t0,t1 #a0 : Periode de deplacement
	#Epilogue
	lw ra,0(sp)
	addi sp,sp,4
	jr ra
	#Fin epilogue

#Resume :
#	Joue une frame : clavier, deplacements, tirs, collisions, puis dessin de la scene dans le buffer
#Preconditions : P_initialiser a ete appele
#Entrees : //
#Sorties :
#	a0 : Etat de la partie (game_running_status, game_victory_status, game_defeat_status
#	     ou game_quit_status)
P_frame :
	#Prologue
	addi sp,sp,-12
	sw ra,0(sp)
	sw s0,4(sp)
	sw s1,8(sp)
	#Fin prologue
	lw s0,P_compteur_frame
	addi s0,s0,1 #s0 : Numero de la frame
	sw s0,P_compteur_frame,t0
	li s1,0 #s1 : 1 si les envahisseurs ont atteint les murs
	#Clavier
	lw a0,J_adresse
	lw a1,M_adresse
	jal J_deplacer
	beqz a0,P_frame_missiles #Si le joueur ne quitte pas, la frame continue
	lw a0,game_quit_status
	j P_frame_fin
	P_frame_missiles :
		lw a0,M_adresse
		jal M_deplacer
	#Deplacement des envahisseurs, une frame sur "periode"
	lw a0,E_adresse
	jal P_periode_envahisseurs
	rem t0,s0,a0 #t0 : Numero de frame modulo la periode
	bnez t0,P_frame_tir_envahisseurs #Si ce n'est pas une frame de deplacement, on passe
	lw a0,E_adresse
	jal E_deplacer
	mv s1,a0 #s1 : 1 si les envahisseurs ont atteint les murs
	P_frame_tir_envahisseurs :
		lw t0,invaders_shot_period
		rem t0,s0,t0 #t0 : Numero de frame modulo la periode de tir
		bnez t0,P_frame_collisions #Si ce n'est pas une frame de tir, on passe
		lw a0,M_adresse
		lw a1,E_adresse
		jal M_envoi_invaders
	P_frame_collisions :
		lw a0,M_adresse
		lw a1,O_adresse
		lw a2,E_adresse
		lw a3,J_adresse
		jal C_collision
		or t0,a0,a1 #t0 : Non nul si des points ont ete gagnes ou si le joueur a ete touche
		beqz t0,P_frame_dessin #Si rien n'a change, le statut n'est pas reaffiche
		lw t0,P_score
		add t0,t0,a0 #t0 : Ajoute les points gagnes au score
		sw t0,P_score,t1
		jal P_afficher_statut
	P_frame_dessin :
		lw a0,I_buff
		jal I_effacer #Repart d'un buffer noir
		lw a0,O_adresse
		jal O_afficher
		lw a0,E_adresse
		jal E_afficher
		lw a0,M_adresse
		jal M_afficher
		lw a0,J_adresse
		jal J_afficher
	#Etat de la partie (si le dernier envahisseur tombe pendant la frame ou le joueur perd sa
	#derniere vie, la victoire l'emporte)
	lw t0,E_adresse
	lw t0,4(t0) #t0 : Envahisseurs en vie
	blez t0,P_frame_victoire #S'il ne reste aucun envahisseur, c'est gagne
	bnez s1,P_frame_defaite #Si les envahisseurs ont atteint les murs, c'est perdu
	lw t0,J_adresse
	lw t0,4(t0) #t0 : Vies du joueur
	blez t0,P_frame_defaite #Si le joueur n'a plus de vie, c'est perdu
	lw a0,game_running_status
	j P_frame_fin
	P_frame_defaite :
		lw a0,game_defeat_status
		j P_frame_fin
	P_frame_victoire :
		lw a0,game_victory_status
	#Epilogue
	P_frame_fin :
		lw ra,0(sp)
		lw s0,4(sp)
		lw s1,8(sp)
		addi sp,sp,12
		jr ra
	#Fin epilogue

#Resume :
#	Termine la partie : encadre la derniere image d'une couleur qui depend du resultat,
#	l'affiche, puis ecrit le resultat et le score final dans la console
#Preconditions : P_frame vient de renvoyer un etat de fin de partie
#Entrees :
#	a0 : Etat de fin de partie renvoye par P_frame
#Sorties : //
P_fin :
	#Prologue
	addi sp,sp,-8
	sw ra,0(sp)
	sw s0,4(sp)
	#Fin prologue
	lw t0,game_victory_status
	beq a0,t0,P_fin_victoire #Separation des cas selon le resultat
	lw t0,game_defeat_status
	beq a0,t0,P_fin_defaite
	#Abandon
	la s0,P_texte_abandon #s0 : Message de fin
	lw a4,P_couleur_abandon #a4 : Couleur du cadre
	j P_fin_cadre
	P_fin_victoire :
		la s0,P_texte_victoire
		lw a4,P_couleur_victoire
		j P_fin_cadre
	P_fin_defaite :
		la s0,P_texte_defaite
		lw a4,P_couleur_defaite
	P_fin_cadre :
		li a0,0
		li a1,0
		lw a2,I_largeur #a2 : Largeur de l'image
		li a3,1
		jal I_rectangle #Bord haut
		lw a1,I_hauteur
		addi a1,a1,-1 #a1 : Derniere ligne de l'image
		jal I_rectangle #Bord bas
		li a1,0
		li a2,1
		lw a3,I_hauteur #a3 : Hauteur de l'image
		jal I_rectangle #Bord gauche
		lw a0,I_largeur
		addi a0,a0,-1 #a0 : Derniere colonne de l'image
		jal I_rectangle #Bord droit
		jal I_buff_to_visu #Affiche la derniere image encadree
	mv a0,s0
	li a7,4
	ecall #Affiche le resultat
	la a0,P_texte_score_final
	li a7,4
	ecall
	lw a0,P_score
	li a7,1
	ecall #Affiche le score final
	la a0,P_texte_saut_ligne
	li a7,4
	ecall
	#Epilogue
	lw ra,0(sp)
	lw s0,4(sp)
	addi sp,sp,8
	jr ra
	#Fin epilogue
