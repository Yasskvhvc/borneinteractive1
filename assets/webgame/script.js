// Sélectionner l'élément canvas et obtenir le contexte pour dessiner
const canvas = document.getElementById('roue');
const ctx = canvas.getContext('2d');

// Options de la roue et leurs couleurs
const options = ['Perdu', '20 % de réduction', 'Perdu', '30 % de réduction !', 'Perdu', '20 % de réduction'];
const couleurs = ['#FF6384', '#FF9F40', '#FF6384', '#FF9F40', '#FF6384', '#FF9F40'];

// Initialisation de l'angle et de la vitesse de rotation
let angleActuel = 0;
let enRotation = false;

// Taille du secteur de chaque option
const angleParOption = (Math.PI * 2) / options.length;

// Éléments du modal
const modal = document.getElementById('resultatModal');
const modalContent = modal.querySelector('.modal-content');
const modalMessage = modal.querySelector('.modal-message');
const modalDescription = modal.querySelector('.modal-description');
const modalButton = modal.querySelector('.modal-button');

// Fonction pour afficher le modal de résultat
function afficherResultat(resultat) {
    const estPerdu = resultat === 'Perdu';
    
    modalContent.className = 'modal-content ' + (estPerdu ? 'perdu' : 'gagne');
    modalMessage.textContent = estPerdu ? '😢 Perdu !' : '🎉 Gagné !';
    modalDescription.textContent = estPerdu ? 
        'Pas de chance cette fois-ci. Retentez votre chance !' : 
        `Félicitations ! Vous avez gagné : ${resultat}`;
    
    modal.classList.add('active');
}

// Fermer le modal quand on clique sur le bouton
modalButton.addEventListener('click', () => {
    modal.classList.remove('active');
});

// Dessiner la roue avec les options et couleurs
function dessinerRoue() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    ctx.translate(canvas.width / 2, canvas.height / 2); // Centrer la roue sur le canvas
    ctx.rotate(angleActuel);

    for (let i = 0; i < options.length; i++) {
        const angle = i * angleParOption;
        
        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.arc(0, 0, 200, angle, angle + angleParOption);
        ctx.lineTo(0, 0);
        ctx.fillStyle = couleurs[i];
        ctx.fill();

        // Ajouter le texte pour chaque option
        ctx.save();
        ctx.rotate(angle + angleParOption / 2);
        ctx.textAlign = 'right';
        ctx.fillStyle = '#fff';
        ctx.font = 'bold 18px Arial';
        ctx.fillText(options[i], 180, 5);
        ctx.restore();
    }

    ctx.restore();

    // Dessiner la flèche fixe au centre du canvas, orientée à droite
    ctx.save();
    ctx.translate(canvas.width / 1, 200); // Positionner la flèche à une distance du centre
    ctx.rotate(Math.PI / 2); // Rotation de 90 degrés pour pointer vers la droite
    ctx.beginPath();
    ctx.moveTo(-15, 0);  
    ctx.lineTo(0, 20);   
    ctx.lineTo(15, 0);   
    ctx.closePath();
    ctx.fillStyle = 'black'; 
    ctx.fill();
    ctx.restore();
}

// Fonction pour animer la rotation de la roue
function tournerRoue() {
    if (enRotation) return;

    enRotation = true;
    const tours = 5 + Math.random() * 5;
    const angleFinal = tours * Math.PI * 2 + Math.random() * Math.PI * 2;
    const dureeAnimation = 5000;
    const tempsDebut = performance.now();

    function animer(tempsActuel) {
        const tempsEcoule = tempsActuel - tempsDebut;
        const progression = Math.min(tempsEcoule / dureeAnimation, 1);

        const easing = t => t < .5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
        angleActuel = easing(progression) * angleFinal;

        dessinerRoue();

        if (progression < 1) {
            requestAnimationFrame(animer);
        } else {
            enRotation = false;

            // Normalisation de l'angle final entre 0 et 2π
            let angleNormalise = (angleActuel % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);

            // Calcul de l'index de la section pointée par la flèche
            let index = Math.floor(angleNormalise / angleParOption);
    
            // Ajuster l'index pour correspondre à la position de la flèche (à droite)
            index = (index + 1) % options.length;

            console.log("Index calculé :", index);
            const resultat = options[index];

            // Affichage du modal avec le résultat de l'option pointée par la flèche
            afficherResultat(resultat);
        }
    }

    requestAnimationFrame(animer);
}

// Dessiner la roue au chargement de la page
dessinerRoue();

// Ajouter un événement au bouton pour faire tourner la roue
document.getElementById('tourner').addEventListener('click', tournerRoue);
