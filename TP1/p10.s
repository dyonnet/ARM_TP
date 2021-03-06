@ File: AddMain.s
.text
.global _start
.extern myAdd

_start:
								@ r9 et r8 contient le code la touche pesée --> 0 au départ
	BL initialise 				@ Appel la routine initialise 

	loop: 						@ boucle principale qui tourne tant que nProd > 0
	swi 0x203 					@ Vérifier si un touche a été pesée
	CMP r0, #0					@ r0 == 0 ?
	BEQ bouton1 				@ SI NON r0 != 0 --> passer aux boutons
	BL keypressed 				@ Si OUI, appeler la routine keypressed qui gère la pression des touches
	b findeboucle 				@ Appel la routine findeboucle

bouton1:
	swi 0x202 					@ Un bouton a été pesé?
	cmp r0, #0					@ Si r0 == 0 Aucune boucle na été préssé.
	BEQ findeboucle 			@ Si r0 == 0 appeler la routine findeboucle
	cmp r0, #1 					@ OUI : Est-ce le bouton #1 ? r0 == 1 ?
	BNE bouton2 				@ NON ==> bouton2 a été pesé --> donner le change
	bl proceedcommande 			@ OUI : traiter la commande
	b findeboucle

bouton2:
	bl change 					@ Appel la routine change pour donner le change

findeboucle:
								@ A-t-on fini?
	LDR r1, =nProd 				@ Charger le nombre de produits en inventaire
	LDR r1, [r1]				@ Mettre la valeur dans r1
	CMP r1, #0 					@ Sil ny a plus rien, quitter r1 == r0
	BNE loop					@Si non on rappel le début de la loop
	SWI 0x11 					@Si oui arrêter le programme



@ ==========initialise===================================
@ routine qui procède à linitialisation des variables
@ La seule variable à initialiser est le nombre de produits
@ en inventaire (disp). Pour ce faire, il faut additionner
@ les inventaires de chaque produit.

initialise:
	STMFD sp!,{lr} 				@Sauvegarde de lenvironement précedent
	mov r9,#0					@Donne la valeur 0 à r9
	mov r8,#0					@Donne la valeur 0 à r8
	bl printdata 				@Appel la routine printdata qui affiche les donnée à lécran 
	LDMFD sp!,{pc}				@Charge lenvironement précedent

@ ===========keypressed===================================
@ routine qui traite une touche du clavier
@ Ici, on détermine quelle touche a été pesée.
@ Si cest un chiffre de 1 à 9, on inscrit le chiffre dans r9 et on met r8 à 0.
@ Si cest de la monnaie, on incrit le montant dans r8
@ Si cest une valeur ilégale, on inscrit le montant dans r8

keypressed:
	STMFD sp!,{lr}  			@Sauvegarde de lenvironement précedent
	mov r9,#0 					@Donne la valeur 0 à r9
	mov r8,#1					@Donne la valeur 1 à r8
findtouch:
	cmp r0,r8 					@Compage r0 et r8
	add r8,r8,r8				@Additionne r8 et r9 dans r8 
	add r9,r9,#1 				@Additionne 1 à r9 dans r9
	bne findtouch 				@Si r0 =! r8 au moment de cmp Saute à  findtouch
	subs r8,r9,#10				@Vérifie si r9 - 10 > 0 et met le résulat dans r8
	bmi selectprod				@ si r9 - 10 < 0 Saute à selectprod car une touche produit a été pesée.
	add r8,r8,#1				@Additionne 1 à r8 dans r8 pour avoir une valeur positive dans r8 
	mov r9,#0					@Donne la valeur 0 à r9 car la valeur dun ajout de monaie est stocker dans r8
	LDMFD sp!,{pc}				@Charge lenvironement précedent
selectprod:
	mov r8,#0					@Donne la valeur 0 à r8 car la valeur dun achat de produit est stocker dans r9
	LDMFD sp!,{pc}				@Charge lenvironement précedent

@============proceedcommande==================================
@ Routine qui fait vérifie q une action a été choisie et appel les routine makecomande et addmoney si une action a faire
@

proceedcommande: 				
	STMFD sp!,{r0-r2,lr}	     	@Sauvegarde de lenvironement précedent
	add r0,r8,r9					@Additionne r8 et r9 dans r0
	cmp r0,#0						@Compare r0 et la valeur 0
	bne execcom						@Si r0 != 0 une action à été faite et on Appel la routine execcom
	ldr r2,=ErrAction				@Si non Une erreur est survenue --> On récupère la valeur de ErrAction dans r2 (valeur à écrire à lécrant)
	mov r0,#5						@Déternime les ordonées pour l affichage
	mov r1,#11						@Détermine les abscises pour l affichage
	swi 0x204						@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)	
execcom:
	bl makecomande					@Appel la routine makecomande
	bl addmoney	  					@Appel la rotine addmoney
	LDMFD sp!,{r0-r2,pc} 			@Charge lenvironement précedent

@===========makecomande==========================================
@Routine qui fait une commande
@

makecomande:
	STMFD sp!,{r0-r7,lr}	   		@Sauvegarde de lenvironement précedent
	cmp r9,#0						@Compare r9 et la valeur 0
	beq endcommande					@Si r9 == 0 Saute à endcommande (pas de commande en vue)
	ldr r6,=solde 					@Si NON r9 != 9 ==> Récupère l adresse de solde dans r6
	ldr r0,[r6]						@Copie la valeur à l adresse r6 dans r0
	mov r7,#4						@Donne la valeur 4 à r7
	sub r9,r9,#1 					@Soustrait 1 à r9 
	mul r7,r9,r7 					@Multiplie r9 et r7 dans r9 (Pour retrouver l index )
	ldr r5,=disp 					@Récupère l adress de disp dans r5
	add r5,r5,r7 					@Avance de la valeur de r7 dans ladresse contenu dans r5 (pour arriver au bon index)
	ldr r2,[r5] 					@Recupère la valeur a ladresse contenu dans r5 dans r2
	ldr r1,=prix 					@Recupère l adress de prix dans r1
	ldr r1,[r1,r7] 					@Recupère la valeur à l adresse de r1 + r7 dans r1
	subs r3,r0,r1 					@Verifie si r0 - r1 > 0 et met la valeur dans r3
	bmi ErrArgentcommande 			@Si r0 - r1 < 0 Saut à ErrArgentcommande (Il n y a pas suffisament d argent pour la commande)
	subs r2,r2,#1 					@Vérifie si r2 - 1 > 0 et met la valeut dans r2
	bmi Errdispcommande				@Si r2 - 1 < 0  Saut à Errdispcommande (L aticle n est pas disponible)
	str r2,[r5]						@Copie dans r2 la valeur à ladresse contenu dans r5
	str r3,[r6]						@Copie dans r3 la valeur à ladresse contenue dans r6
	mov r9,#0						@Donne la valeur 0 à r9
	bl printdata 					@Apelle la routine printdata
	b endcommande					@Saut à endcommande
ErrArgentcommande:
	ldr r2,=ErrArgent 				@Récupère ladresse de ErrArgent dans r2 pour l affichage
	mov r0,#5 						@Déternime les ordonées pour l affichage
	mov r1,#11 						@Détermine les abscises pour l affichage
	swi 0x204						@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
	b endcommande
Errdispcommande:
	ldr r2,=Errdisp 				@Récupère ladresse de Errdisp dans r2 pour l affichage
	mov r0,#5						@Déternime les ordonées pour l affichage
	mov r1,#11						@Détermine les abscises pour l affichage
	swi 0x204						@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
endcommande:
	LDMFD sp!,{r0-r7,pc} 			@Charge lenvironement précedent

addmoney:
	STMFD sp!,{r5-r7,lr} 			@Sauvegarde de lenvironement précedent
	cmp r8,#0						@Compare r8 et la valeur 0
	beq endaddmoney					@Si r8 == 0 Saut à endaddmoney
	ldr r6,=monnaie	 				@Recupère ladresse de monnaie dans r6
	mov r7,#4 						@Donne la valeur 4 à r7 (4Octect)
	mul r7,r8,r7 					@Multiplie r8 et r7 dans r7 pour récupèrer l index du tableau monnaie
	ldr r6,[r6,r7] 					@Recupère la valeur à ladresse r6 + r7 dans r6 (pour la valeur a ajouter au solde)
	ldr r7,=solde 					@Recupère ladresse de solde dans r7
	ldr r5,[r7]						@Recupère la valeur à ladresse r7 dans r5 (le solde)
	add r5,r5,r6 					@Additionne au solde la valeur à ajouter
	ldr r4,=soldemax 				@Recupère ladresse de soldemax dans r4
	ldr r4,[r4]						@Recupère la valeur à ladresse contenu dans r4 dans r4
	subs r4,r5,r4					@Vérifie si r5 - r4 > 0 et stocke le resultat dans r4
	bmi execaddmonay 				@Si r5 - r4 > 0 Saute à execaddmonay
	ldr r2,=ErrToMoney				@Si non Recupère ladresse de ErrToMoney dans r2 (Le solde est supérieur a la valeur max)
	mov r0,#5	 					@Déternime les ordonées pour l affichage
	mov r1,#11						@Détermine les abscises pour l affichage
	swi 0x204						@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
	b endaddmoney					@Saute à endaddmoney
execaddmonay:
	str r5,[r7] 					@Copie dans la memoire r5 à ladresse contenu dans r7 (le nouveau solde)
	mov r8,#0						@Met la valeur 0 dans r8
	bl printdata 					@Appel la routine printdata
endaddmoney:
	LDMFD sp!,{r5-r7,pc} 			@Charge lenvironement précedent


@==========change===============================================
@Routine qui rend la monnaie
@Affiche un message derreur si il ny a pas de monnaie à rendre
@

change:
STMFD sp!,{r5-r7,lr} 				@Sauvegarde de lenvironement précedent
ldr r6,=solde         				@Recupère ladresse de solde dans r6
ldr r6,[r6] 						@Recupère dans r6 la valeur à ladresse contenu dans r6
cmp r6,#0 							@Compare r6 avec la valeur 0
bne execchange 						@Si r6 != 0 Saut à execchange
ldr r2,=ErrArgent 					@Si non Recupère ladresse de ErrArgent dans r2 ( Le solde est déjà à 0 pas de monnaie à rendre)
mov r0,#5							@Déternime les ordonées pour l affichage
mov r1,#11							@Détermine les abscises pour l affichage
swi 0x204							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
	b endchange						@Saute à endchange
execchange:
	mov r5, #0						@Donne la valeur 0 à r5
	str r5,[r6] 					@Ecrit en memoire la valeur de r5 à l adresse contenu dans r6 (nouveau solde à 0) 
	bl printdata 					@Appel la routine printdata
endchange:
	LDMFD sp!,{r5-r7,pc} 			@Charge lenvironement précedent


@=============printdata==================================
@Routine qui affiche les totalités des infomations à l ecran
@ -le tableau produit (tableau de la description des produits)
@ -le tableau disp (tableau de disponibilitées des produits)
@ -le solde 
@

printdata:
STMFD sp!,{r0-r5,lr}  				@Sauvegarde de lenvironement précedent
swi 0x206 							@Efface l ecran
mov r1,#0
ldr r2,=p0
swi 0x204							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
mov r1,#1
ldr r4,=disp 						@Recupère l adresse de disp dans r4
ldr r3,=produit 					@recupère l adresse de produit dans r3

printdataloop:
mov r0,#0							@Déternime les ordonées pour l affichage
ldr r2,[r3]
swi 0x204							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
mov r0,#20							@Déternime les ordonées pour l affichage
ldr r2,[r4]
swi 0x205							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est une string)

add r4,r4,#4						@Avance de 4octect dans l'adresse de disp (va au int suivant du tableau des disponibilitées)
add r3,r3,#4						@Avance de 4octect dans l'adresse de produit (va au int suivant du tableau de produits)
add r1,r1,#1						@Ajoute 1 à r1
cmp r1,#10							@Compage r1 et la valeur 10
bne printdataloop					@ Si r1 != 10 il reste des produit à afficher (Saute à printdataloop) 
									
									@Affichage du solde

mov r0,#0							@Déternime les ordonées pour l affichage
mov r1,#12							@Détermine les abscises pour l affichage
ldr r2,=strsolde 					@Recupère l adresse de strsolde dans r2 (pour l affiche)
swi 0x204							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
ldr r0,=solde 						@Recupère l adresse de solde dans r0
ldr r0,[r0] 						@Donne la valeur à ladresse de r0 dans r0
mov r1,#100							@Donne la valeur 100 à r1 pour la routine Udiv (Correspond au diviseur)
bl UDiv 							@Appel la routine Udiv 
mov r2,r1 							@Donne la valeur de r1 à r2 (résulat de la division et valeur à afficher à l ecran)
mov r3,r0 							@Donne la valeur de r0 à r3 (reste de la division)
mov r0,#21							@Déternime les ordonées pour l affichage
mov r1,#12							@Détermine les abscises pour l affichage
swi 0x205							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est une string)
mov r0,#24							@Déternime les ordonées pour l affichage
ldr r2,=separate					@Récupère l adresse de separate dans r2
swi 0x204							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est un interger)
mov r5,#10							@Donne la valeur 10 à r5
SUBS r4,r3,r5 						@Vérifie si r3 - r5 > 0 et met la valeur dans r4
bmi addzero							@si r3 - r5 < 0 saute à addzero

endofsolde:
mov r2,r3							@Donne la valeur de r3-->(cent) à r2 (valeur à écrire à l écrant)
mov r0,#26							@Déternime les ordonées pour l affichage
swi 0x205							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est une string)
ldr r2,=currency					@Récupère l adresse de currency dans r2 (valeur à écrire à lécrant)
mov r0,#28							@Déternime les ordonées pour l affichage
swi 0x204							@On affiche à lecrant en fonction de r0, r1 et r2
LDMFD sp!,{r0-r5,pc} 				@Charge lenvironement précedent

addzero:
mov r2,#0							@Donne la valeur 0 à r2 (valeur à écrire à l écrant) 
mov r0,#25							@Déternime les ordonées pour l affichage
swi 0x205							@Affiche à lecran en fonction de r0, r1 et r2 (si r2 est une string)
b endofsolde						@Saute à endofsolde


; ============= UDiv =======================================
; Routine qui effectue une division entière (non-signée).
; Cette routine ne perturbe le contenu daucun registre à
; lexception de
; r0 : le reste de la division
; r1 : le quotient
; r2 : code derreur (1 --> division par zéro)
; Pour utiliser la routine, placer le dividende dans r0 et
; le diviseur dans r1

UDiv:
	STMFD sp!, {r4, lr}
	MOV r2, #0 						@ par défaut, pas derreur
	MOVS r1, r1 					@ tester si le diviseur = 0
	BNE DivOK
	MOV r2, #1 						@ mettre le code derreur à 1
	BAL EndDiv
	DivOK: MOV r4, #0 				@ init le quotient à 0

PasFini:
	ADD r4, r4, #1 					@ incrémenter le quotient
	SUBS r0, r0, r1 				@ Dividende = dividende – diviseur
	BCS PasFini 					@ Dividende >= 0 ==> pas fini!
	ADD r0, r0, r1 					@ On a soustrait une fois de trop ==> restaurer
	SUB r4, r4, #1 					@ On corrige le quotient
	MOV r1, r4 						@ le quotient est mis dans r1

EndDiv:
	LDMFD sp!, {r4, pc}


.data

@ Déclaration des produits
p0: .asciz "Code Description Prix Disp."
p1: .asciz "1 Chips 1.25"
p2: .asciz "2 Chocolat 1.50"
p3: .asciz "3 Fromage 2.95"
p4: .asciz "4 Gateau 1.60"
p5: .asciz "5 Yogourt 1.25"
p6: .asciz "6 Lait 1.40"
p7: .asciz "7 Muffin 1.80"
p8: .asciz "8 Arachides 2.00"
p9: .asciz "9 Bonbons 1.25"

@ Déclaration dun tableau de chaines pour le 9 produits
produit:
.word p1
.word p2
.word p3
.word p4
.word p5
.word p6
.word p7
.word p8
.word p9

@ Déclaration du tableau contenant les quantités disponibles
disp: .word 10,20,10,8,12,6,8,20,15

@ Déclaration du tableau des prix des produits
prix: .word 125, 150, 295, 160, 125, 140, 180, 200, 125
monnaie: .word 0, 200, 100, 25, 10, 0, 0, 0
solde: .word 0
soldemax: .word 995
nProd: .word 9

@Solde
strsolde: .asciz "Votre solde est de : "
separate: .asciz ","
currency: .asciz "$"

@Messages d erreur
ErrArgent: .asciz   "Pas de tune        "
Errdisp: .asciz     "Plus de produit    "
ErrAction: .asciz   "Aucune selection   "
ErrToMoney: .asciz  "Trop dbillet Mamen"
Errtouch: .asciz    "Mauvaise touche    "

.end