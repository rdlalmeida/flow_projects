const questions = [
    [
        // Level 1
        {
            questionText: "Which phase of the internet was read only?",
            answerOptions: [
                { answerText: "web1.0", "isCorrect": true },
                { answerText: "web2.0", "isCorrect": false },
                { answerText: "web3.0", "isCorrect": false },
                { answerText: "web4.0", "isCorrect": false }
            ]
        },
        {
            questionText: "In which phase is the internet decentralized?",
            answerOptions: [
                { answerText: "web1.0", "isCorrect": false },
                { answerText: "web2.0", "isCorrect": false },
                { answerText: "web3.0", "isCorrect": true },
                { answerText: "web4.0", "isCorrect": false }
            ]
        },
        {
            questionText: "A user can own data on web1.0?",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "How many locations does web2.0 use to store accessible data?",
            answerOptions: [
                { answerText: "Three locations", "isCorrect": false },
                { answerText: "One location", "isCorrect": true },
                { answerText: "No locations", "isCorrect": false },
                { answerText: "Seven locations", "isCorrect": false }
            ]
        },
        {
            questionText: "How does one access data on web3.0?",
            answerOptions: [
                { answerText: "A magic whiteboard", "isCorrect": false },
                { answerText: "Snail main in a PO Box", "isCorrect": false },
                { answerText: "In a blockchain", "isCorrect": true },
                { answerText: "Through a well tuned microwave", "isCorrect": false }
            ]
        },
        {
            questionText: "The transactions on the Blockchain are easy to change with the right coding knowledge.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "Satoshi Nakamoto invented blockchain technology.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "What is the name of the coin/token on the FLOW blockchain?",
            answerOptions: [
                { answerText: "ETHER", "isCorrect": false },
                { answerText: "FLOW", "isCorrect": true },
                { answerText: "BITCOIN", "isCorrect": false },
                { answerText: "RIVER", "isCorrect": false }
            ]
        },
        {
            questionText: "In the simplest terms the blockchain is:",
            answerOptions: [
                { answerText: "DJANGO UNCHAINED", "isCorrect": false },
                { answerText: "Database of an immutable ledger of transactions", "isCorrect": true },
                { answerText: "What your parents told you to stay away from.", "isCorrect": false },
                { answerText: "Satoshi Nakamoto’s creation", "isCorrect": false }
            ]
        },
        {
            questionText: "What makes the blockchain technology so valuable is its centralized construction",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        }
    ],
    [
        // Level 2
        {
            questionText: "What is cryptocurrency at its core?",
            answerOptions: [
                { answerText: "code", "isCorrect": true },
                { answerText: "a scam", "isCorrect": false },
                { answerText: "magic", "isCorrect": false },
                { answerText: "a piece of bread", "isCorrect": false }
            ]
        },
        {
            questionText: "What is considered the original cryptocurrency?",
            answerOptions: [
                { answerText: "credit cards", "isCorrect": false },
                { answerText: "Ethereum", "isCorrect": false },
                { answerText: "Bitcoin", "isCorrect": true },
                { answerText: "gold", "isCorrect": false }
            ]
        },
        {
            questionText: "Cryptocurrency can be taken from its owner without their authorization",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "You can hide how much cryptocurrency you own",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "What did the FLOW cryptocurrency trade at its highest price?",
            answerOptions: [
                { answerText: "$19.00", "isCorrect": false },
                { answerText: "$29.00", "isCorrect": false },
                { answerText: "$39.00", "isCorrect": true },
                { answerText: "$49.00", "isCorrect": false }
            ]
        },
        {
            questionText: "NFT stands for:",
            answerOptions: [
                { answerText: "NOT FOR TODDLERS", "isCorrect": false },
                { answerText: "NON-FUNGIBLE TOKEN", "isCorrect": true },
                { answerText: "NASCENT FACE TATTOO", "isCorrect": false },
                { answerText: "NORMAL FREE THOUGHT", "isCorrect": false }
            ]
        },
        {
           questionText: "NFTs are all the same",
           answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "Popular NFT projects on FLOW are:",
            answerOptions: [
                { answerText: "CRYPTOKITTIES & BAYC", "isCorrect": false },
                { answerText: "HOODLUMS & NBA HOTSHOT ", "isCorrect": true },
                { answerText: "JEEPERS CREEPERS & LOVELORN", "isCorrect": false },
                { answerText: "CRY ME A RIVER & RIVERDANCE", "isCorrect": false }
            ]
        },
        {
            questionText: "NFT are a type of cryptocurrency",
            answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": false }
            ]
        },
        {
            questionText: "NFT became popular in",
            answerOptions: [
                { answerText: "1972", "isCorrect": false },
                { answerText: "2018", "isCorrect": false },
                { answerText: "2020", "isCorrect": true },
                { answerText: "2009", "isCorrect": false }        ]
        }
    ],
    [
        // Level 3
        {
            questionText: "Once you lose your seed phrase to a wallet there is no way to access what is inside the wallet",
            answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": false }
            ]
        },
        {
            questionText: "Your private identifying information is stored in your Web3 Wallet",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "What are the three main wallets used with FLOW?",
            answerOptions: [
                { answerText: "MetaMask, BLOCTO, and dapper", "isCorrect": false },
                { answerText: "Dapper, BLOCTO, and Lilico", "isCorrect": true },
                { answerText: "Hansel, Gretzel, and Blitzen", "isCorrect": false },
                { answerText: "Larry, curly, and mo", "isCorrect": false }
            ]
        },
        {
            questionText: "What are seed phrases?",
            answerOptions: [
                { answerText: "How to grow your crypto portfolio", "isCorrect": false },
                { answerText: "how to make a mountain out of a mole hill", "isCorrect": false },
                { answerText: "how to access your web3 wallet", "isCorrect": true },
                { answerText: "how to send money to your web3 wallet", "isCorrect": false }
            ]
        },
        {
            questionText: "You can withdraw cryptocurrency from a wallet using its public key",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "Strangers who reach out to you for keys or passwords are friends waiting to happen.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
           questionText: "Legitimate cryptocurrencies have whitepapers.",
           answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": false  }
            ]
        },
        {
            questionText: "Huge returns are guaranteed in the crypto space.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "If a celebrity promotes a crypto it is guaranteed legitimate.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "You a smart, you are good looking, and everybody likes you.",
            answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": true }
            ]
        }
    ],
    [
        // Level 4
        {
            questionText: "Who should you give your seed phrase to?",
            answerOptions: [
                { answerText: "no one", "isCorrect": true },
                { answerText: "your mother", "isCorrect": false },
                { answerText: "Santa claus", "isCorrect": false },
                { answerText: "a financial advisor", "isCorrect": false }
            ]
        },
        {
            questionText: "It is safe to take a screenshot of your seed phrase",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "What is a cold wallet?",
            answerOptions: [
                { answerText: "a bear market wallet", "isCorrect": false },
                { answerText: "a wallet with a virus", "isCorrect": false },
                { answerText: "a wallet not connected to the internet", "isCorrect": true },
                { answerText: "a mean wallet", "isCorrect": false }
            ]
        },
        {
            questionText: "Giveaways are a great what to get free cryptocurrencies and NFTs.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "What should you invest in when it comes to a Web3 Wallet?",
            answerOptions: [
                { answerText: "lots of FLOW", "isCorrect": false },
                { answerText: "A new laptop", "isCorrect": false },
                { answerText: "a cold wallet", "isCorrect": true },
                { answerText: "a sub-zero wallet", "isCorrect": false }
            ]
        },
        {
            questionText: "DAO stands for:",
            answerOptions: [
                { answerText: "DECENT AUTO OIL", "isCorrect": false },
                { answerText: "DECENTRALIZED AUTONOMOUS ORGANIZATION", "isCorrect": true },
                { answerText: "DECENTRALIZED AUTOMATIC OPTIONS", "isCorrect": false },
                { answerText: "DECENTRALIZED AUTOIMMUNE ORAFICE", "isCorrect": false }
            ]
        },
        {
            questionText: "DAOs are nothing like traditional real world companies.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "Examples of DAOs on the FLOW blockchain:",
            answerOptions: [
                { answerText: "PETER, PAUL & MARY", "isCorrect": false },
                { answerText: "EMERALD CITY & FLOVATAR", "isCorrect": true },
                { answerText: "BARTER YARD CLUB & ATOMIC DOG", "isCorrect": false },
                { answerText: "FLOVATAR & FLOJO", "isCorrect": false }
            ]
        },
        {
            questionText: "You must be a member of a DAO to vote on decisions regarding that DAO.",
            answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": false }        
            ]
        },
        {
            questionText: "You need to know coding to be a part of a DAO.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        }
    ],
    [
        // Level 5
        {
            questionText: "DEFI has third party intermediaries like banks and brokers for the safety of the market.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "DEFI stands for:__________________",
            answerOptions: [
                { answerText: "Definitely Financing", "isCorrect": false },
                { answerText: "Deferred Finality", "isCorrect": false },
                { answerText: "Decentralized Finance", "isCorrect": true },
                { answerText: "Decent Finish", "isCorrect": false }
            ]
        },
        {
            questionText: "There are little risks in DEFI because it is based on code not people’s actions",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "DEFI instruments range from ___________ to _________",
            answerOptions: [
                { answerText: "Good, Bad", "isCorrect": false },
                { answerText: "Conservative, Volatile", "isCorrect": true },
                { answerText: "Local, National", "isCorrect": false },
                { answerText: "Boring, Exciting", "isCorrect": false }
            ]
        },
        {
            questionText: "DEFI is just like traditional financial instruments, but it uses the blockchain.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "Nodes are what make recording and securing transactions possible on the blockchain.",
            answerOptions: [
                { answerText: "True", "isCorrect": true },
                { answerText: "False", "isCorrect": false }
            ]
        },
        {
            questionText: "FLOW is a proof-of-work blockchain.",
            answerOptions: [
                { answerText: "True", "isCorrect": false },
                { answerText: "False", "isCorrect": true }
            ]
        },
        {
            questionText: "You can earn Bitcoin with nodes by:",
            answerOptions: [
                { answerText: "STAKING", "isCorrect": false },
                { answerText: "MINING", "isCorrect": true },
                { answerText: "TRADING", "isCorrect": false },
                { answerText: "PRINTING", "isCorrect": false }
    
            ]
        },
        {
            questionText: "Crypto Nodes are also known as:",
            answerOptions: [
                { answerText: "Bad for the environment", "isCorrect": false },
                { answerText: "Computer Nodes", "isCorrect": true },
                { answerText: "Great paper weights", "isCorrect": false },
                { answerText: "Satoshi Nakamoto’s creation", "isCorrect": false }
            ]
        },
        {
            questionText: "Each Node keeps a copy of:",
            answerOptions: [
                { answerText: "Shakespeare", "isCorrect": false },
                { answerText: "War & Peace", "isCorrect": false },
                { answerText: "Your Personal Information", "isCorrect": false },
                { answerText: "the Blockchain", "isCorrect": true }
            ]
        }
    ]
]

export { questions }