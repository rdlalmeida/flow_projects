import React, { useState, useEffect } from "react";
import { questions } from "./components/Questions";
import * as fcl from "@onflow/fcl";
import "./flow/config.js";
import styles from "./styles/nav.css";
import testTransaction from "./flow/cadence/transactions/TestTransaction.cdc";
import createShapesCollection from "./flow/cadence/transactions/createShapesCollection.cdc";
import getCollectionStatus from "./flow/cadence/scripts/getCollectionStatus.cdc";
import getEventIDs from "./flow/cadence/scripts/getEventIDs.cdc";
import getFLOATCollectionStatus from "./flow/cadence/scripts/getFLOATCollectionStatus.cdc";
import createUserFLOATCollection from "./flow/cadence/transactions/createUserFLOATCollection.cdc";
import claimFLOATtoUserCollection from "./flow/cadence/transactions/claimFLOATtoUserCollection.cdc";
import getFlowVaultStatus from "./flow/cadence/scripts/getFlowVaultStatus.cdc";
import buySquare from "./flow/cadence/transactions/buySquare.cdc";
import collectionUpgrade from "./flow/cadence/transactions/upgradeCollection.cdc";
import getShapeLevel from "./flow/cadence/scripts/getShapeLevel.cdc";

function App() {
    console.log("Starting this bullshit...");

    const [question_level, setQuestionLevel] = useState(0);
    const [current_questions, setQuestionSet] = useState(
        questions[question_level]
    );
    const [currentQuestion, setCurrentQuestion] = useState(0);
    const [showScore, setShowScore] = useState(false);
    const [score, setScore] = useState(0);
    const [user, setUser] = useState({ loggedIn: false });
    const shapeContractAddr = "0xb7fb1e0ae6485cf6";
    const floatEventIds = [
        136770190, 136770191, 136770192, 136770193, 136770194,
    ];

    useEffect(() => {
        fcl.currentUser.subscribe(setUser);
    }, []);

    // ------------------ CADENCE TRANSACTIONS AND SCRIPTS ------------------------------------------
    const gas_limit = 999;
    // Simple test function
    async function runAltTestTransaction() {
        const transactionText = await fetch(testTransaction).then((r) =>
            r.text()
        );

        const transactionId = await fcl.mutate({
            cadence: transactionText,
            args: null,
            // args: (arg, t) => [
            // 	arg(user.addr, t.Address)
            // ],
            proposer: fcl.authz,
            payer: fcl.authz,
            authorizations: [fcl.authz],
            limit: gas_limit,
        });

        console.log(
            "Alt transaction successfully executed with id " + transactionId
        );
    }

    // Function that lets a user buy a Square to start the quiz
    async function purchaseSquare() {
        const qlevel = await getQuestionLevel();

        if (qlevel == 0) {
            const transactionText = await fetch(buySquare).then((r) =>
                r.text()
            );

            const transactionId = await fcl.mutate({
                cadence: transactionText,
                args: (arg, t) => [arg(shapeContractAddr, t.Address)],
                proposer: fcl.authz,
                payer: fcl.authz,
                authorizations: [fcl.authz],
                limit: gas_limit,
            });

            console.log(
                "Account " +
                    user.addr +
                    " successfully bought a Square from " +
                    shapeContractAddr +
                    ". TransactionID = " +
                    transactionId
            );
        } else if (qlevel == 1) {
            alert("Account " + user.addr + " already has a Square!");
        } else {
            alert(
                "Account " +
                    user.addr +
                    " already has some other shape already!"
            );
        }
    }

    // Function to upgrade a Collection up level upgrade by switching the current shape with the next one
    async function upgradeCollection() {
        const transactionText = await fetch(collectionUpgrade).then((r) =>
            r.text()
        );

        const transactionId = await fcl.mutate({
            cadence: transactionText,
            args: (arg, t) => [arg(shapeContractAddr, t.Address)],
            proposer: fcl.authz,
            payer: fcl.authz,
            authorizations: [fcl.authz],
            limit: gas_limit,
        });

        console.log(
            "Account " +
                user.addr +
                " successfully upgraded!. TransactionID = " +
                transactionId
        );
    }

    // Function to claim a FLOAT at the end of a learning level
    async function claimFLOAT() {
        const transactionText = await fetch(claimFLOATtoUserCollection).then(
            (r) => r.text()
        );

        const transactionId = await fcl.mutate({
            cadence: transactionText,
            args: (arg, t) => [
                arg(user.addr, t.Address),
                arg(floatEventIds[question_level], t.Int),
            ],
            proposer: fcl.authz,
            payer: fcl.authz,
            authorizations: [fcl.authz],
            limit: gas_limit,
        });
        console.log("FLOAT claimed with transaction " + transactionId);
    }

    // Function to determine the level in which the user is, based on the shape in its collection
    async function getQuestionLevel() {
        const scriptText = await fetch(getShapeLevel).then((r) => r.text());

        const questionLevel = await fcl.query({
            cadence: scriptText,
            args: (arg, t) => [arg(user.addr, t.Address)],
        });

        console.log("Account " + user.addr + " Shape level: " + questionLevel);

        return questionLevel;
    }

    // Function to return the ids all Events. The Ids are ordered by level, i.e., lowest ID = lowest Level and so on
    async function getAllEventIDs() {
        const scriptText = await fetch(getEventIDs).then((r) => r.text());

        const floatEventIds = await fcl.query({
            cadence: scriptText,
            args: (arg, t) => [arg(shapeContractAddr, t.Address)],
        });

        return floatEventIds;
    }

    // Function to detect if a Shape Collection exists in the user address
    async function getShapeCollectionStatus() {
        const scriptText = await fetch(getCollectionStatus).then((r) =>
            r.text()
        );

        const result = await fcl.query({
            cadence: scriptText,
            args: (arg, t) => [arg(user.addr, t.Address)],
        });

        return result;
    }

    // Function to detect if FLOAT Collection exists in the user address
    async function getFLOATCollectionExists() {
        const scriptText = await fetch(getFLOATCollectionStatus).then((r) =>
            r.text()
        );

        const result = await fcl.query({
            cadence: scriptText,
            args: (arg, t) => [arg(user.addr, t.Address)],
        });

        return result;
    }

    async function getFlowVaultExists() {
        const scriptText = await fetch(getFlowVaultStatus).then((r) =>
            r.text()
        );

        const result = await fcl.query({
            cadence: scriptText,
            args: (arg, t) => [arg(user.addr, t.Address)],
        });

        //console.log(result ? "User " + user.addr + " has a Flow Vault configured" : "User " + user.addr + " does not have a Flow Vault in it!")
        console.log(result);
    }

    // Function to create a FLOAT Collection into the user's account
    async function createFLOATCollection() {
        const transactionText = await fetch(createUserFLOATCollection).then(
            (r) => r.text()
        );

        const transactionId = await fcl.mutate({
            cadence: transactionText,
            args: null,
            proposer: fcl.authz,
            payer: fcl.authz,
            authorizations: [fcl.authz],
            limit: gas_limit,
        });

        console.log("FLOAT Collection transaction id = " + transactionId);
    }

    // Function to create a Shape Collection
    async function createShapeCollection() {
        const transactionText = await fetch(createShapesCollection).then((r) =>
            r.text()
        );

        const transactionId = await fcl.mutate({
            cadence: transactionText,
            args: null,
            proposer: fcl.authz,
            payer: fcl.authz,
            authorizations: [fcl.authz],
            limit: gas_limit,
        });

        console.log("Shape Collection transaction id = " + transactionId);
    }

    // ----------------------------------------------------------------------------------------------

    async function logInUser() {
        if (user.loggedIn) {
            alert("User ".concat(user.addr).concat(" is already logged in!"));
        } else {
            fcl.authenticate();
        }
    }

    async function resolveShapeCollection() {
        await getShapeCollectionStatus().then((colStatus) => {
            colStatus
                ? alert(
                      "Account " + user.addr + " already has a Shape Collection"
                  )
                : createShapeCollection();
        });
    }

    async function resolveFLOATCollection() {
        await getFLOATCollectionExists().then((colStatus) => {
            colStatus
                ? alert(
                      "Account " + user.addr + " already has a FLOAT Collection"
                  )
                : createFLOATCollection();
        });
    }

    function logOffUser() {
        if (user.loggedIn) {
            fcl.unauthenticate();
        }
    }

    const handleAnswerOptionClick = (isCorrect) => {
        if (isCorrect) {
            setScore(score + 1);
        }

        const nextQuestion = currentQuestion + 1;
        if (nextQuestion < current_questions.length) {
            setCurrentQuestion(nextQuestion);
        } else {
            setShowScore(true);
        }
    };

    const resetQuiz = () => {
        setCurrentQuestion(0);
        setScore(0);
        setShowScore(false);
    };

    // This use effect runs every time the question level is updated, which should only happen in the advanceQuestionLevel function
    // By some reason, setting the new question set after setting the new question level was repeating one of the questions sets, but with this
    // useEffect it now works!
    useEffect(() => {
        setQuestionSet(questions[question_level]);
    }, [question_level]);

    async function advanceQuestionLevel() {
        const qlevel = await getQuestionLevel();
        if (qlevel <= question_level) {
            // Only upgrade the collection if the shape level is less or equal to the question level
            // To avoid wrongful upgrades
            await upgradeCollection();
        }
        await setQuestionLevel(question_level + 1);
        // The new question set is updated with the useEffect above
        // setQuestionSet(questions[question_level])
        await setScore(0);
        await setShowScore(false);
        await setCurrentQuestion(0);
    }

    // -------------------------------- ELEMENT RENDERING FUNCTIONS ---------------------------------
    const Quiz = () => {
        return (
            <>
                <div className="question-section">
                    <div className="question-count">
                        <h3>Level {question_level + 1}</h3>
                        <span>Question {currentQuestion + 1}</span>/
                        {current_questions.length}
                    </div>
                    <div className="question-text">
                        {current_questions[currentQuestion].questionText}
                    </div>
                </div>
                <div className="answer-section">
                    {current_questions[currentQuestion].answerOptions.map(
                        (answerOption) => (
                            <button
                                onClick={() =>
                                    handleAnswerOptionClick(
                                        answerOption.isCorrect
                                    )
                                }
                            >
                                {answerOption.answerText}
                            </button>
                        )
                    )}
                </div>
            </>
        );
    };

    const Score = () => {
        if (score < current_questions.length) {
            return (
                <div className="score-section">
                    You scored {score} out of {current_questions.length}.
                    {score < current_questions.length / 2
                        ? "\nHumm, you need to study some more"
                        : "\nAlmost there..."}
                    <button onClick={resetQuiz}>Restart level</button>
                </div>
            );
        } else {
            return (
                <div className="score-section">
                    Congratulations, you scored {score} out of{" "}
                    {current_questions.length}!
                    <button onClick={claimFLOAT}>Claim FLOAT</button>
                    <button onClick={advanceQuestionLevel}>Next Level</button>
                </div>
            );
        }
    };

    // ----------------------------------------------------------------------------------------------

    return (
        <div>
            <nav className={styles.Nav}>
                <h1>Noobs to Flowstars</h1>
                <button onClick={logInUser}>
                    {user.loggedIn
                        ? "Wallet ".concat(user.addr).concat(" connected!")
                        : "Connect wallet"}
                </button>
                <button onClick={logOffUser}>
                    {user.loggedIn
                        ? "Disconnect wallet"
                        : "Wallet not connected"}
                </button>
            </nav>
            <footer className={styles.footer}>
                <h1>Collection Setup</h1>
                {user.loggedIn ? (
                    <div>
                        <button onClick={resolveShapeCollection}>
                            Get a Shape Collection
                        </button>
                        <button onClick={resolveFLOATCollection}>
                            Get a FLOAT Collection
                        </button>
                        <button onClick={purchaseSquare}>Buy a Square</button>
                    </div>
                ) : (
                    <div className="setup">
                        <div className="score-section">
                            Connect a wallet to start!
                        </div>
                    </div>
                )}
            </footer>
            <h1>Questionnaire: </h1>
            <div className="app">
                {user.loggedIn ? (
                    showScore ? (
                        <Score />
                    ) : (
                        <Quiz />
                    )
                ) : (
                    <div className="score-section">
                        Log in and get your Collections to play the quiz
                    </div>
                )}
            </div>
        </div>
    );
}

export default App;
