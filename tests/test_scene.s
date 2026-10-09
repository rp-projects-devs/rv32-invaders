####################################################################################################
#                                  TEST VISUEL : SCENE (prefixe T_)                                #
####################################################################################################
#
# A lancer dans RARS avec le Bitmap Display connecte (memes reglages que le jeu).
# Cree toutes les structures, ajoute un missile de chaque camp et affiche la scene initiale :
# verifie les fonctions de creation et de dessin de donnees.s.

.text
	j T_main

.include "../src/config.s"
.include "../src/affichage.s"
.include "../src/donnees.s"

.text

T_main :
	jal I_creer
	sw a0,I_visu,t0 #Alloue l'image affichee (debut du tas)
	jal I_effacer
	jal I_creer
	sw a0,I_buff,t0 #Alloue le buffer
	jal I_effacer
	jal J_creer
	mv s0,a0 #s0 : Adresse de la structure joueur
	jal E_creer
	mv s1,a0 #s1 : Adresse de la structure envahisseurs
	jal O_creer
	mv s2,a0 #s2 : Adresse de la structure obstacles
	jal M_creer
	mv s3,a0 #s3 : Adresse de la structure missiles
	mv a0,s3
	li a1,15
	li a2,16
	lw a3,missiles_direction_up
	jal M_ajouter_missile #Missile du joueur
	mv a0,s3
	li a1,8
	li a2,14
	lw a3,missiles_direction_down
	jal M_ajouter_missile #Missile d'un envahisseur
	mv a0,s2
	jal O_afficher
	mv a0,s1
	jal E_afficher
	mv a0,s3
	jal M_afficher
	mv a0,s0
	jal J_afficher
	jal I_buff_to_visu #Affiche la scene
	li a7,10
	ecall
