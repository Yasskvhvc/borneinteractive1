const lever = document.getElementById("lever");
const reels = document.querySelectorAll(".reel");
const resultText = document.getElementById("result");

const symbols = ["🍒", "🍋", "🔔", "⭐", "🍉"];

function spinReels() {
    lever.classList.add("active");

    setTimeout(() => {
        let randomIndexes = [
            Math.floor(Math.random() * symbols.length),
            Math.floor(Math.random() * symbols.length),
            Math.floor(Math.random() * symbols.length),
        ];

        // 50% de chances de laisser une combinaison gagnante
        if (Math.random() < 0.5) {
            while (
                randomIndexes[0] === randomIndexes[1] &&
                randomIndexes[1] === randomIndexes[2]
            ) {
                randomIndexes[2] = Math.floor(Math.random() * symbols.length);
            }
        }

        reels.forEach((reel, index) => {
            reel.textContent = symbols[randomIndexes[index]];
        });

        lever.classList.remove("active");
        checkWin();
    }, 1000);
}

function checkWin() {
    let values = [...reels].map((reel) => reel.textContent);
    let isWin = values.every((val, _, arr) => val === arr[0]);

    if (isWin) {
        if (Math.random() < 0.99) {  // 99% de chances de valider la victoire
            window.location.href = "win.html";
        } else {
            resultText.textContent = "Dommage, presque ! Retentez votre chance.";
        }
    } else {
        resultText.textContent = "Vous avez perdu, retentez votre chance !";
    }
}

lever.addEventListener("click", spinReels);
