####################################################################################################
#                                         RV32 INVADERS                                            #
####################################################################################################
#
# Point d'entree du jeu. A ouvrir et assembler dans RARS (voir README.md pour la configuration
# du Bitmap Display et du Keyboard and Display MMIO Simulator).
#
# Les modules sont inclus a plat, dans l'ordre de leurs dependances. Chaque module ne contient que
# des donnees et des fonctions : la premiere instruction executee est donc le saut vers main.

.text
	j main

.include "config.s"
.include "affichage.s"
.include "son.s"
.include "donnees.s"
.include "mouvement.s"
.include "collisions.s"
.include "partie.s"

.text

main :
	li a7,30
	ecall #a0 : Temps courant (32 bits de poids faible), utilise comme graine aleatoire
	jal P_initialiser
	main_boucle :
		jal P_frame #a0 : Etat de la partie
		lw t0,game_running_status
		bne a0,t0,main_fin #Si la partie est terminee, sort de la boucle
		jal I_buff_to_visu #Affiche la frame
		lw a0,frame_delay
		li a7,32
		ecall #Attend la duree d'une frame
		j main_boucle
	main_fin :
		jal P_fin #a0 : Etat de fin de partie, transmis a P_fin
		li a7,10
		ecall #Fin du programme
