import React from "react";
import ReactDOM from "react-dom/client";

function LandingApp() {
  return <h1>Corra Booth Landing Page</h1>;
}

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <LandingApp />
  </React.StrictMode>
);

