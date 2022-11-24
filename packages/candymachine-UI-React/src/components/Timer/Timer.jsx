import React, { useEffect, useRef, useState } from "react";
import "./Timer.css";

export const Timer = ({ countDownDate }) => {
  const [days, setDays] = useState("00");
  const [hours, setHours] = useState("00");
  const [minutes, setMinutes] = useState("00");
  const [seconds, setSeconds] = useState("00");

  let interval = useRef();

  const startTimer = (countDownDate) => {
    // const countDownDate =
    //   process.env.REACT_APP_TIME ||
    //   new Date(process.env.REACT_APP_DATE).getTime();

    interval = setInterval(() => {
      const now = new Date().getTime();
      const distance = new Date(countDownDate).getTime() - now;
      const days = Math.floor(distance / (1000 * 60 * 60 * 24));
      const hours = Math.floor(
        (distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60)
      );
      const minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((distance % (1000 * 60)) / 1000);
      if (distance < 0) {
        //stop timer
        clearInterval(interval.current);
      } else {
        //update timer
        setDays(days);
        setHours(hours);
        setMinutes(minutes);
        setSeconds(seconds);
      }
    }, 1000);
  };
  useEffect(() => {
    startTimer(countDownDate);
    return () => {
      clearInterval(interval.current);
    };
  });
  return (
    <section className="timer-container">
      <div className="timer">
        <section>
          <p>{days}</p>
          <p>
            <small>Days</small>
          </p>
        </section>
        <section>
          <p>{hours}</p>
          <p>
            <small>Hours</small>
          </p>
        </section>
        <section>
          <p>{minutes}</p>
          <p>
            <small>Minutes</small>
          </p>
        </section>
        <section>
          <p>{seconds}</p>
          <p>
            <small>Seconds</small>
          </p>
        </section>
      </div>
    </section>
  );
};
