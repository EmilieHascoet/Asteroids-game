/////////////////////////////////////////////////////
//
// Asteroids
// DM2 "UED 131 - Programmation impérative" 2021-2022
// NOM         :  HASCOET
// Prénom      :  Emilie
// N° étudiant :  20212051
//
// Collaboration avec : 
//
/////////////////////////////////////////////////////
// import un module pour les sons
import processing.sound.*;

//===================================================
// les variables globales
//===================================================

///////////////////////
// Pour le vaisseau  //
///////////////////////
float shipX, shipY;       // position
float shipAngle;          // angle
float shipVx, shipVy;     // vecteurs vitesse
float shipAx, shipAy;     // vecteurs accélération
boolean engine;           // moteur allumé ou non
SoundFile engineSound;    // son du moteur

//////////////////////
// Pour le missile  //
//////////////////////
float[][] bulletXY;       // position
float[][] bulletVxy;      // vecteurs vitesse
int bulletMax;            // nombre maximum
int bulletCurrent;        // nombre courant
int lastShoot;            // delay avant de tirer
SoundFile bulletSound;    // son du missile

//////////////////////
// Pour l'astéroïde //
//////////////////////
float[][] asteroidXY;       // position
int[] asteroidSize;         // taille
float[][] asteroidShape;    // forme
float[] asteroidAngle;      // angle
float[][] asteroidAxy;      // accélération
float[][] asteroidVxy;      // vecteurs vitesse
int asteroidInit;           // nombre initial
int asteroidMax;            // nombre maximum
int asteroidCurrent;        // nombre courant
int[] asteroidDestroy;      // nombre détruis
SoundFile bangSSound;       // son petite collisions
SoundFile bangLSound;       // son grosse collisions

////////////////////////////
// Pour la gestion du jeu //
////////////////////////////
int life;                 // nombre de vies du joueur
int start;                // millisecondes depuis le lancement de la partie
int ms;                   // millisecondes de la partie
int score;                // points du joueur
int delay;                // lancement d'un delay en millisecondes
float level;              // niveau du jeu
boolean init;             // écran d'acceuil ou non
boolean levelChoice;      // écran choix du niveau ou non 
boolean invincible;       // le vaisseau est insensible aux collisions ou non
boolean gameOver;         // fin de partie ou non
SoundFile background;     // musique de fond

////////////////////////////////////
// Pour la gestion de l'affichage //
////////////////////////////////////
PFont fontSmall;       // police d'écriture petite Anakin
PFont fontLarge;       // police d'écriture grande Anakin
PFont fontAndalemo;    // police d'écriture Andalemo plus lisible

//===================================================
// l'initialisation
//===================================================
void setup() {
  // paramètres de la fenêtre
  size(800, 800);
  background(0);
  // crée les polices d'écritures
  fontSmall = createFont("AnakinmonoRegular.ttf", 20);
  fontLarge = createFont("AnakinmonoRegular.ttf", 80);
  fontAndalemo = createFont("Andalemo.ttf", 20);
  // charge les sons
  engineSound = new SoundFile(this, "thrust.mp3");
  bulletSound = new SoundFile(this, "fire.mp3");
  bangSSound = new SoundFile(this, "bangSmall.mp3");
  bangLSound = new SoundFile(this, "bangLarge.mp3");
  background = new SoundFile(this, "Hacking to The Gate (8-Bit).mp3");
  // initialisation des astéroïdes
  asteroidInit = 5;
  asteroidMax = 100;
  asteroidXY = new float [asteroidMax][2];
  asteroidSize = new int [asteroidMax];
  asteroidAngle = new float [asteroidMax];
  asteroidVxy = new float [asteroidMax][2];
  asteroidShape = new float [asteroidMax][6];
  asteroidDestroy = new int [3];
  // initialisation des missiles
  bulletMax = 10;
  bulletXY = new float [bulletMax][2];
  bulletVxy = new float [bulletMax][2];
  // initialise le jeu
  init = true;
  levelChoice = false;
  level = 1;
}

// -------------------- //
// Initialise le jeu    //
// -------------------- //
void initGame() {
  // initialise les paramètres du vaisseau
  initShip();
  // crée la première vague d'astéroïdes
  asteroidCurrent = 0;
  initAsteroids(0, asteroidInit);
  // nombre de missile
  bulletCurrent = 0;
  // pas de delay avant de tirer
  lastShoot = 0;
  // nombre de vie
  life = 3;
  invincible = false;
  // lancement du chrono
  start = millis();
  // réinitialise à 0 le score
  for (int i=0; i<3; i++)
    asteroidDestroy[i] = 0;
  score = 0;
  // lancement de la musique de fond
  background.loop(0.95, 0.5);
}

//===================================================
// la boucle de rendu
//===================================================
void draw() {
  // écrand d'acceuil
  if (init) {
    displayInitScreen();
  }
  // écrand choix du niveau
  else if (levelChoice) {
    displayLevelScreen();
  }
  // si le joueur a perdu
  else if (gameOver){
      background.stop();
      displayGameOverScreen();
  }
  // si la partie continue
  else {
    // repeins la fenêtre en noir
    background(0);
    // fait clignoter le vaisseau pendant 3 secondes lorsqu'il est invincible
    if (invincible) {
      if (frameCount%20 < 10)
        displayShip();
      if (millis() - delay > 3000)
        invincible = false;
    } else 
      displayShip();
    // annule les effets de translation et de rotation
    resetMatrix();
    // déplace le vaisseau
    moveShip();
    // diminue le temps d'attente avant le prochain tire
    lastShoot--;
    // affiche et déplace tous les missiles qui sont sur le champs de jeu
    for (int i=0; i<bulletCurrent; i++) {
      displayBullets(i);
      moveBullets(i);
    }
    // affiche et déplace tous les astéroïdes qui sont sur le champs de jeu
    for (int i=0; i<asteroidCurrent; i++) {
      displayAsteroids(i);
      moveAsteroids(i);
      // test les collisions entre les missiles et les astéroïdes qui sont sur le champs de jeu
      for (int j=0; j<bulletCurrent; j++) {
        // calcule le diamètre moyen de l'astéroïde
        float diameter = averageDiameter(i);
        // si il y a collision entre un missile et un astéroïde
        if (collision(bulletXY[j][0], bulletXY[j][1], 0, asteroidXY[i][0], asteroidXY[i][1], diameter)) {
          // division en deux ou suppression de l'astéroïde
          shootAsteroid(i, bulletVxy[j][0], bulletVxy[j][1]);
          // supprime le missile
          deleteBullet(j);
          // si le nombre d'astéroïde sur le champs de jeu ne dépasse pas le nombre max d'astéroïde autorisé : 
          // tous les 10 astéroïdes détruis ajoute 1 astéroïde puis 2, puis 3 ect...
          int sumAsteroidDestroy = asteroidDestroy[0] + asteroidDestroy[1] + asteroidDestroy[2];
          if (asteroidCurrent < asteroidMax && sumAsteroidDestroy%10 == 0) {
            initAsteroids(asteroidCurrent, sumAsteroidDestroy/10);
          }
        }
      }
    }
    // test les collisions entre le vaisseau et les astéroïdes qui sont sur le champs de jeu
    for(int i=0; i<asteroidCurrent; i++) {
      // calcule le diamètre moyen de l'astéroïde
      float diameter = averageDiameter(i);
      // si il y a collision entre le vaisseau et un astéroïde lorsque le vaisseau n'est pas invincible
      if (collision(shipX, shipY, 10, asteroidXY[i][0], asteroidXY[i][1], diameter) && !invincible) {
        // retire une vie au joueur
        shipCollision(i);
      }
    }
    // affiche les vies restantes du joueur
    displayLife();
    // calcule puis affiche le temps de jeu
    ms = millis() - start;
    displayChrono();
    // calcule puis affiche le score du joueur (score en fonction de la taille des astéroïdes et du niveau de jeu)
    score = (asteroidDestroy[0]*60 + asteroidDestroy[1]*30 + asteroidDestroy[2]*10) * int(pow(level, 2));
    displayScore();
  }
}

// ------------------------ //
//  Initialise le vaisseau  //
// ------------------------ //
void initShip() {
  // coordonnées au centre de la fenêtre
  shipX = width/2;
  shipY = height/2;
  // orientation vers le haut
  shipAngle = 3*PI/2;
  // vecteurs vitesse null : le vaisseau ne bouge pas
  shipVx = 0;
  shipVy = 0;
}

// --------------------- //
//  Deplace le vaisseau  //
// --------------------- //
void moveShip() {
  // mise à jour vecteurs vitesse
  shipVx += shipAx;
  shipVy += shipAy;
  // mise à jour des coordonnées + effet "wraparound"
  shipX = (shipX + shipVx + width) % width;
  shipY = (shipY + shipVy + height) % height;
}

// -------------------------- //
//  Crée un nouvel asteroïde  //
// -------------------------- //
void initAsteroid(int idx) {
  // taille aléatoire, taille possible : 30, 60 ou 90
  asteroidSize[idx] = (int(random(3))+1) * 30;    // 
  // coordonnées aléatoires
  float bord = int(random(4));    // choix du bord aléatoire
  // place l'astéroïde de façon aléatoire en fonction du bord choisis
  asteroidXY[idx][0] = ((bord+1)%2) * random(width) + width * int(bord/3);
  asteroidXY[idx][1] = (bord%2) * random( height) + height * int(((3-bord)/3));
  // crée la forme aléatoire de l'astéroïde
  createAsteroid(idx);
  // direction aléatoire de l'astéroïde 
  asteroidAngle[idx] = radians(random(360));
}

void initAsteroids(int idx, int nbAsteroid) {
  // crée le nombre d'astéroïde demandé à l'indice donnée
  for(int i=idx; i<nbAsteroid; i++){
    initAsteroid(i);
    asteroidCurrent++;
  }
}

// ------------------------------ //
//  Crée la forme de l'asteroïde  //
// ------------------------------ //
// i : l'indice de l'asteroïde dans le tableau
//
void createAsteroid(int idx) {
  // valeurs aléatoires pour la forme de l'astéroïde
  for (int i=0; i<6; i++){
    asteroidShape[idx][i] = random(0.2, 1);
  }
}

// --------------------- //
//  Deplace l'asteroïde  //
// --------------------- //
/**la vitesse des astéroïdes varie en fonction de la taille et du niveau :
- astéroïde de taille 90 : vitesse = 2 * niveau (1 ou 1.5)
- astéroïde de taille 60 : vitesse = 3,5 * niveau (1 ou 1.5)
- astéroïde de taille 30 : vitesse = 5 * niveau (1 ou 1.5)
*/
void moveAsteroids(int idx) {
  // mise à jour vecteurs vitesse
  asteroidVxy[idx][0] = (5 - (asteroidSize[idx] / 30)) * level * cos(asteroidAngle[idx]);
  asteroidVxy[idx][1] = (5 - (asteroidSize[idx] / 30)) * level * sin(asteroidAngle[idx]);
  // mise à jour des coordonnées + effet "wraparound"
  asteroidXY[idx][0] = (asteroidXY[idx][0] + asteroidVxy[idx][0] + width) % width;
  asteroidXY[idx][1] = (asteroidXY[idx][1] + asteroidVxy[idx][1] + height) % height;
}

// ------------------------ //
//  Détecte les collisions  //
// ------------------------ //
// o1X, o1Y : les coordonnées (x,y) de l'objet1
// o1D      : le diamètre de l'objet1 
// o2X, o2Y : les coordonnées (x,y) de l'objet2
// o2D      : le diamètre de l'objet2 
//
// calcule le diamètre moyen de l'asteroïde
float averageDiameter(int idx){
  float sum = 0;
  for (int i=0; i<asteroidShape[idx].length; i++) {
    // additionne toutes les valeurs du tableau à l'indice donné
    sum += asteroidShape[idx][i];
  }
  return sum/asteroidShape[idx].length * asteroidSize[idx];
}

boolean collision(float o1X, float o1Y, float o1D, float o2X, float o2Y, float o2D) {
  // si la distance entre le centre des deux objets est inférieurs à leurs rayons additionnés alors il y a collision
  if(dist(o1X, o1Y, o2X, o2Y) - (o1D + o2D)/2 < 0) return true;
  else return false;
}

// --------------------- //
//  Son de la collision  //
// --------------------- //
void collisionSound(int size) {
  if (size == 30)
    bangSSound.play();
  else
    bangLSound.play();
}

// ----------------- //
//  Tire un missile  //
// ----------------- //
void shoot() {
  // si le nombre de missile sur le champs de jeu n'a pas atteint le nombre max de missile autorisé
  if (bulletCurrent < bulletMax) {
    // son du missile
    bulletSound.play();
    // position du missile au bout du corps du vaisseau
    bulletXY[bulletCurrent][0] = shipX + 10*cos(shipAngle);
    bulletXY[bulletCurrent][1] = shipY + 10*sin(shipAngle);
    // vecteurs vitesse du missile
    bulletVxy[bulletCurrent][0] = 5 * cos(shipAngle);
    bulletVxy[bulletCurrent][1] = 5 * sin(shipAngle);
    // un missile en plus sur le champs de jeu
    bulletCurrent++;
  }
}

// ------------------------------------------- //
//  Calcule la trajectoire du ou des missiles  //
// ------------------------------------------- //
void moveBullets(int idx) {
  // mise à jours de la position du missile
  bulletXY[idx][0] += bulletVxy[idx][0];
  bulletXY[idx][1] += bulletVxy[idx][1];
  // supprime le missile si il touche le bord
  if (bulletXY[idx][1] < 0 || bulletXY[idx][0] > width || bulletXY[idx][1] > height || bulletXY[idx][0] < 0) {
    deleteBullet(idx);
  }
}

// --------------------- //
//  Supprime un missile  //
// --------------------- //
// idx : l'indice du missile à supprimer
//
void deleteBullet(int idx) {
  // supprime le missile à l'indice donné
  // en décalant toutes les coordonnées des missiles (contenu dans un tableau) vers la gauche
  for (int i=idx; i<bulletXY.length-1; i++) {
    for (int j=0; j<bulletXY[i].length; j++) {
      bulletXY[i][j] = bulletXY[i+1][j];
      bulletVxy[i][j] = bulletVxy[i+1][j];
    }
  }
  // un missile en moins sur le champs de jeu
  bulletCurrent--;
}

// --------------------- //
//  touche un astéroïde  //
// --------------------- //
// idx    : l'indice de l'atéroïde touché
// vx, vy : le vecteur vitesse du missile
//
void shootAsteroid(int idx, float vx, float vy) {
  // son de la collision
  collisionSound(asteroidSize[idx]);
  // incrémente le nombre d'astéroïdes détruis de la taille de l'astéroïde touché
  asteroidDestroy[(asteroidSize[idx]/30)-1]++;
  // enregistre les paramètres de l'astéroïde touché dans un tableau
  float[] parameter = {asteroidSize[idx], asteroidXY[idx][0], asteroidXY[idx][1]};
  // supprime l'astéroïde touché
  deleteAsteroid(idx);
  // si astéroïde de taille 30 ou trop d'astéroïde sur le champs de jeu
  if (parameter[0] == 30 || asteroidCurrent >= asteroidMax) {
    // 50% de chance d'en créer un nouveau de position et taille aléatoires
    if (random(2) < 1) {
      initAsteroids(asteroidCurrent, 1);
    } 
    // si aucun astéroïde sur le champs de jeu crée une nouvelle vague de 5 astéroïdes
    else if (asteroidCurrent == 0) {
      initAsteroids(0, asteroidInit);
    }
  }
  // si asteroid de taille 60 ou 90 :
  // division en deux astéroïdes plus petits de même taille chacun
  else if (parameter[0] == 60 || parameter[0] == 90) {
    for (int i=0; i<2; i++) {
      asteroidSize[asteroidCurrent] = int(parameter[0] - 30);
      asteroidXY[asteroidCurrent][0] = parameter[1];
      asteroidXY[asteroidCurrent][1] = parameter[2];
      asteroidAngle[asteroidCurrent] = atan2(vy, vx) + radians(random(-90, 90));
      createAsteroid(asteroidCurrent);
      asteroidCurrent++;
    }
  }
}

// ----------------------- //
//  supprime un astéroïde  //
// ----------------------- //
// idx    : l'indice de l'atéroïde touché
//
void deleteAsteroid(int idx) {
  // supprime l'astéroïde à l'indice donné
  // en décalant tous les paramètres des astéroïdes (contenu dans des tableaux) vers la gauche
  for (int i=idx; i<asteroidXY.length-1; i++) {
    asteroidSize[i] = asteroidSize[i+1];
    asteroidAngle[i] = asteroidAngle[i+1];
    asteroidShape[i] = asteroidShape[i+1];
    for (int j=0; j<asteroidXY[i].length; j++) {
      asteroidXY[i][j] = asteroidXY[i+1][j];
      asteroidVxy[i][j] = asteroidVxy[i+1][j];
    }
  }
  // un astéroïde en moins sur le champs de jeu
  asteroidCurrent--;
}

// --------------------------------- //
//  le vaisseau touche un astéroïde  //
// --------------------------------- //
// idx    : l'indice de l'atéroïde touché
//
void shipCollision(int idx) {
  // son de la collision
  collisionSound(asteroidSize[idx]);
  // retire une vie au joueur
  life--;
  // replace le vaisseau au centre
  initShip();
  // vaisseau insensible aux collisions pendant 5 secondes
  invincible = true;
  delay = millis();
  // si le joueur n'a plus de vie : le joueur a perdu
  if (life == 0) {
    // mise à jour de la variable gameOver
    gameOver = true;
  }
}

//===================================================
// Gère les affichages
//===================================================

// ------------------- //
// Ecran d'accueil     //
// ------------------- //
void displayInitScreen() {
  // repeins la fenêtre en noir
  background(0);
  // TITRE
  fill(0, 255, 0);              // couleur verte
  textAlign(CENTER, CENTER);    // alignement du texte
  textFont(fontLarge);          // police d'ecriture
  text("ASTEROIDS", width/2, 180);
  // LANCER LE JEU
  // effet clignotant
  if (frameCount%80 < 50) {
    textFont(fontSmall);    // police d'ecriture
    text("ENTREE pour JOUER", width/2, height - 70);
  }
  // PRINCIPE DU JEU
  // variables placement du texte
  int spaceBetweenLines = 30;
  int startText = 285;
  // paramètres
  fill(255);                    // couleur blanche
  textAlign(LEFT, TOP);         // alignement du texte
  textFont(fontAndalemo);    // police d'ecriture
  // contenu du texte à afficher
  String[] textAndalemo = {
    "Vous êtes confronté à des champs d'astéroïdes.",
    "Le but est de survivre le plus longtemps possible",
    "en évitant les astéroïdes et en les détruisant.",
    "",
    "",
    "COMMANDES",
    "=========",
    "► = tourne sur la droite",
    "◄ = tourne sur la gauche",
    "▲ = allume le moteur",
    "ESPACE = tire",
    "ENTER/RETURN = téléportation aléatoire",
  };
  // affiche le texte d'explication
  for (int i=0; i<textAndalemo.length; i++) {
    text(textAndalemo[i], 65, startText + i * spaceBetweenLines);
  }
  // DESSIN DECORATIF
  // vaisseau
  rotate(radians(-30));
  scale(4);
  strokeWeight(1.70);
  fill(0);
  int[] white = {255, 255, 255};
  engineDraw(10, 33);
  shipDraw(10, 33, white);
  // missiles
  bulletsDraw(10, 33);
  // astéroïdes
  asteroidInitDraw(170, 125);
}

// ----------------------- //
//  Ecran choix du niveau  //
// ----------------------- //
void displayLevelScreen(){
  // repeins la fenêtre en noir
  background(0);
  // TITRE
  fill(0, 255, 0);              // couleur verte
  textAlign(CENTER, CENTER);    // alignement du texte
  textFont(fontLarge);          // police d'ecriture
  text("ASTEROIDS", width/2, 180);
  // LANCER LE JEU
  textFont(fontSmall);
  // effet clignotant
  if (frameCount%80 < 50) {
    text("ENTREE pour JOUER", width/2, height - 70);
  }
  // BULLE CHOIX DE LA DIFFICULTE
  // éclaire en vert le rectangle de gauche
  if (level == 1) {
    fill(125, 240, 140);
    rect(63, 340, 300, 50);
    fill(0);
    text("FACILE", 213, 365);
    rect(428, 340, 300, 50);
    fill(255);
    text("DIFFICILE", 578, 365);
  }
  // éclaire en vert le rectangle de droite
  if (level == 1.5) {
    fill(125, 240, 140);
    rect(428, 340, 300, 50);
    fill(0);
    text("DIFFICILE", 578, 365);
    rect(63, 340, 300, 50);
    fill(255);
    text("FACILE", 213, 365);
  }
  // texte au dessus des rectangles
  textFont(fontAndalemo);
  text("Veuillez choisir le niveau :", width/2, 291);
  // AFFICHAGE DES POINTS QUE RAPPORTE LES ASTEROÏDES DETRUIS
  text("Points :", width/2, 433);
  textAlign(LEFT);
  int[] points = {10, 30, 60};
  // niveau facile
  for (int i=0; i<3; i++) {
    asteStatDraw(170, 500 + 75*i, 90 - 30*i);
    fill(255);
    text("=", 230, 510 + 75*i);
    text(points[i], 270, 510 + 75*i);
  }
  // niveau difficile
  for (int i=0; i<3; i++) {
    asteStatDraw(530, 500 + 75*i, 90 - 30*i);
    fill(255);
    text("=", 590, 510 + 75*i);
    text(points[i]*2, 630, 510 + 75*i);
  }
  // DESSIN DECORATIF
  // vaisseau
  rotate(radians(-30));
  scale(4);
  strokeWeight(1.70);
  fill(0);
  int[] white = {255, 255, 255};
  engineDraw(10, 33);
  shipDraw(10, 33, white);
  // missiles
  bulletsDraw(10, 33);
}

// -------------- //
//  Ecran de fin  //
// -------------- //
void displayGameOverScreen() {
  // GAME OVER
  // paramètres du texte
  fill(0, 255, 0);              // couleur verte
  textAlign(CENTER, CENTER);    // alignement du texte
  textFont(fontLarge);          // police d'ecriture
  // texte au centre
  text("GAME OVER", width/2, height/2);
  
  //temporisation de 2 secondes avant affichage des statistiques
  if (millis() - delay > 2000) {
    // repeins la fenêtre
    background(0);
    text("GAME OVER", width/2, 180);
    // STATISTIQUES DE FIN DE PARTIE
    // paramètres
    textFont(fontAndalemo);    // police d'ecriture
    fill(255);                 // couleur blanche
    // texte sous le titre au milieu
    text("Astéroïdes détruis :", width/2, 320);
    
    // dessin astéroïdes et nombres détruis
    textAlign(LEFT);
    strokeWeight(3);
    for (int i=0; i<3; i++) {
      asteStatDraw(110 + 235*i, 415, 90 - 30*i);
      fill(0, 255, 0);    // texte en vert
      text("=", 170 + 235*i, 423);
      text(asteroidDestroy[2-i], 210 + 235*i, 423);
    }
    // affichage du timer et du score 
    textAlign(CENTER);
    textFont(fontSmall);
    fill(255);
    // texte à gauche
    text("Time : " + ms/60000 + ":" + (ms/1000)%60, width/4 + 25, 550);
    // texte à droite
    text("Score : " + score, 3*width/4 - 25, 550);
    
    // RELANCER LE JEU
    // effet clignotant
    if (frameCount%80 < 50) {
      fill(0, 255, 0);
      text("ENTREE pour REJOUER", width/2, height - 65);
    }
    // DESSIN DECORATIF
    // vaisseau
    rotate(radians(-30));
    scale(4);
    strokeWeight(1.70);
    fill(0);
    int[] white = {255, 255, 255};
    engineDraw(10, 33);
    shipDraw(10, 33, white);
    // missiles
    bulletsDraw(10, 33);
  }
}

// --------------------- //
//  Affiche le vaisseau  //
// --------------------- //
void displayShip() {
  // paramètres du vaisseau
  strokeWeight(2);            // épaisseur des trais
  translate(shipX, shipY);    // position du vaisseau
  rotate(shipAngle);          // angle du vaisseau
  // si le moteur est allumé
  if (engine) {
    // flammes du réacteur
    engineDraw(0, 0);
  }
  // corps du vaisseau
  int[] white = {255, 255, 255};    // contour blanc
  fill(0);                          // remplissage noir
  shipDraw(0, 0, white);
}

// ------------------------ //
//  Affiche les asteroïdes  //
// ------------------------ //
void displayAsteroids(int idx) {
  stroke(255);    // contour blanc
  fill(0);        // remplissage noir
  // polygone de "rayon" aléatoire
  beginShape();
  // à partir du centre du polygone ajoute le diamètre divisé par deux (30/2, 60/2 ou 90/2 en fonction de la taille de l'astéroïde)
  // qui est multiplié par une valeur comprise entre 0.2 et 1 puis effectue une rotation de 60° pour calculer le prochain point du polygone
  // vertex(x + taille/2 * random(0.2, 1) * cos(60° * i), y + taille/2 * random(0.5, 1) * sin(60° * i))
  for (int i=0; i<6; i++){
    vertex(asteroidXY[idx][0] + asteroidSize[idx]/2*asteroidShape[idx][i] * cos(radians(60*(i+1))), asteroidXY[idx][1] + asteroidSize[idx]/2* asteroidShape[idx][i] * sin(radians(60*(i+1))));
  }
  endShape(CLOSE);
}

// ---------------------- //
//  Affiche les missiles  //
// ---------------------- //
void displayBullets(int idx) {
  stroke(255);    // couleur blanche
  // ligne correspondant à un missile
  line(bulletXY[idx][0], bulletXY[idx][1], bulletXY[idx][0] + bulletVxy[idx][0], bulletXY[idx][1] + bulletVxy[idx][1]);
}

// ------------------ //
//  Affiche les vies  //
// ------------------ //
void displayLife() {
  // paramètres du texte
  fill(0, 255, 0);            // couleur verte
  textAlign(LEFT, CENTER);    // position du texte
  textFont(fontSmall);        // police d'ecriture
  // texte en haut à gauche
  text("Life :", 50, 50);
  
  // vaisseau correspondant aux vies restantes
  int[] green = {0, 255, 0};
  strokeWeight(2);
  noFill();
  rotate(3*PI/2);
  translate(-53, 120);
  for (int i=1; i<=life; i++) {
    translate(-30, 25);
    shipDraw(30*i, 0, green);
  }
  resetMatrix();
}

// ------------------- //
//  Affiche le chrono  //
// ------------------- //
void displayChrono() {
  // paramètres du texte
  fill(0, 255, 0);              // couleur verte
  textAlign(CENTER, CENTER);    // position du texte
  textFont(fontSmall);          // police d'ecriture
  // texte en haut au milieu
  text("Time : " + ms/60000 + ":" + (ms/1000)%60, width/2, 50);
}

// ------------------- //
//  Affiche le score   //
// ------------------- //
void displayScore() {
  // paramètres du texte
  fill(0, 255, 0);             // couleur verte
  textAlign(RIGHT, CENTER);    // position du texte
  textFont(fontSmall);         // police d'ecriture
  // texte en haut à droite
  text("Score :" + score, width-50, 50);
}

// --------- //
//  Dessins  //
// --------- //

// flammes du réacteur
void engineDraw(int x, int y) {
  stroke(255, 0, 0);    // contour en rouge
  fill(0);              // remplissage noir
  // polygone
  beginShape();   
  vertex(x - 15, y);
  vertex(x - 5, y - 5);
  vertex(x - 5, y + 5);
  endShape(CLOSE);
}

// corps du vaisseau
void shipDraw(int x, int y, int[] couleur) {
  // conteur de la couleur donné en paramètre
  stroke(couleur[0], couleur[1], couleur[2]);
  // polygone
  beginShape();   
  vertex(x - 5, y);
  vertex(x - 7, y - 7);
  vertex(x + 10, y);
  vertex(x - 7, y + 7);
  endShape(CLOSE);
}

// missiles écran d'acceuil
void bulletsDraw(int x, int y) {
  stroke(255);    // missile en blanc
  for (int i=0; i<3; i++) {
    line(x + 25 * (i+1), y, x + 30 + 25 * i, y);
    rotate(radians(8));
  }
}

// astéroïdes écran d'acceuil
void asteroidInitDraw(int x, int y) {
  // réinitialise les rotations
  rotate(radians(6));
  // gros astéroïde
  beginShape();   
  vertex(x + 15, y);
  vertex(x + 5, y + 10);
  vertex(x - 5, y + 10);
  vertex(x - 5, y + 5);
  vertex(x - 10, y + 5);
  vertex(x, y - 5);
  vertex(x, y - 10);
  vertex(x + 5, y - 10);
  endShape(CLOSE);
  // petits astéroïdes
  beginShape();
  vertex(x - 7.5, y - 15);
  vertex(x - 12.5, y - 15);
  vertex(x - 17.5, y - 5);
  endShape(CLOSE);
  beginShape();
  vertex(x - 22.5, y - 10);
  vertex(x - 25, y - 5);
  vertex(x - 27.5, y - 10);
  endShape(CLOSE);
  beginShape();
  vertex(x - 15, y + 12.5);
  vertex(x - 15, y + 17.5);
  vertex(x - 20, y + 25);
  vertex(x - 20, y + 17.5);
  vertex(x - 25, y + 17.5);
  vertex(x - 22.5, y + 12.5);
  endShape(CLOSE);
}

// astéroïdes en forme de félin
void asteStatDraw(int x, int y, int t) {
  t /= 10;
  stroke(255);    // contour blanc
  fill(0);        // remplissage noir
  // polygone en forme de félin
  beginShape();
  vertex(x + t, y - 3*t);
  vertex(x + 2*t, y - 4*t);
  vertex(x + 3*t, y - 3*t);
  vertex(x + 3*t, y - 2*t);
  vertex(x + 4*t, y - t);
  vertex(x + 4*t, y + t);
  vertex(x + t, y + 4*t);
  vertex(x - t, y + 4*t);
  vertex(x - 4*t, y + t);
  vertex(x - 4*t, y - t);
  vertex(x - 3*t, y - 2*t);
  vertex(x - 3*t, y - 3*t);
  vertex(x - 2*t, y - 4*t);
  vertex(x - t, y - 3*t);
  endShape(CLOSE);
}

//===================================================
// Gère l'interaction clavier
//===================================================

// ------------------------------- //
//  Quand une touche est enfoncée  //
// ------------------------------- //
// flèche droite  = tourne sur droite
// flèche gauche  = tourne sur la gauche
// flèche haut    = accélère
// barre d'espace = tire
// entrée         = téléportation aléatoire
//
void keyPressed() {
  // passe à l'écran du choix du niveau
  if (init || (gameOver &&  millis() - delay > 3000)) {
    if (key == ENTER || key == RETURN) {
      levelChoice = true;
      init = false;
      gameOver = false;
    }
  }
  /**
  Ecran choix du niveau
  - flèche gauche = facile
  - flèche droite = difficile
  - entrée/ return = lance la partie
  */
  else if (levelChoice) { //<>//
    if (key == CODED) {
      if (keyCode == RIGHT) {
      level = 1.5;
      } else if (keyCode == LEFT) {
        level = 1;
      }
    } else if (key == ENTER || key == RETURN) {
      initGame();
      levelChoice = false;
    }
  }
  // contrôle du vaisseau
  else if (key == CODED) {
    if (keyCode == RIGHT) {
      // tourne le vaisseau de 5 degrées vers la droite
      shipAngle += radians(5);
    } else if (keyCode == LEFT) {
      // tourne le vaisseau de 5 degrées vers la gauche
      shipAngle -= radians(5);
    } else if (keyCode == UP){
      if (!engine) {
        // son du moteur juste la première fois qu'on appuie sur l'accélérateur
        engineSound.play();
      }
      // allume le moteur
      engine = true;
      // vecteurs accélération du vaisseau
      shipAx = 0.25 * cos(shipAngle);
      shipAy = 0.25 * sin(shipAngle);
    }
  }
  // lance un missile
  else if (key == ' ') {
    // tire au plus une fois tous les 5 appels de draw
    if (lastShoot <= 0) {
      shoot();
      lastShoot = 5;
    }
  }
  // téléportation du vaisseau aléatoire
  else if (key == ENTER || key == RETURN) {
    shipX = random(width);
    shipY = random(height);
  }
}

// ------------------------------- //
//  Quand une touche est relâchée  //
// ------------------------------- //
void keyReleased() {
  // relâche la flèche du haut
  if (key == CODED) {
    if (keyCode == UP) {
      // éteins le moteur
      engine = false;
      // vecteurs accélération du vaisseau
      shipAx = 0.0;
      shipAy = 0.0;
    }
  }
}
