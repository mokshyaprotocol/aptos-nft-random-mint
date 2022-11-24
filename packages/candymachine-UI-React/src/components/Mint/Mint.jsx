import React, { useState } from "react";
import "./Mint.css";
import { Button } from "@mui/material";
export const Mint = ({ mintStart, mint }) => {
  return (
    <div className="mint-btn-container">
      <div className="mint-btn">
        <Button variant="contained" disabled={!mintStart} onClick={mint}>
          Mint
        </Button>
      </div>
    </div>
  );
};
