import { useRef, useEffect } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

const Marquee = ({ text, speed = 1, reverse = false }) => {
  const marqueeRef = useRef(null);
  const contentRef = useRef(null);

  useEffect(() => {
    const marquee = marqueeRef.current;
    const content = contentRef.current;
    
    // Duplicate content for seamless loop
    const clone = content.cloneNode(true);
    marquee.appendChild(clone);

    const width = content.offsetWidth;
    
    // Initial position
    if (reverse) {
        gsap.set(marquee, { x: -width });
    }

    const anim = gsap.to(marquee, {
      x: reverse ? 0 : -width,
      duration: width / (100 * speed),
      ease: "none",
      repeat: -1,
      overwrite: true
    });

    return () => {
      anim.kill();
    };
  }, [text, speed, reverse]);

  return (
    <div className="relative w-full overflow-hidden whitespace-nowrap py-4 border-y border-swiss-white/10">
      <div ref={marqueeRef} className="inline-block">
        <div ref={contentRef} className="inline-block text-6xl font-swiss font-bold text-swiss-white/80 px-4 tracking-tighter">
          {text} &nbsp; {text} &nbsp; {text} &nbsp;
        </div>
      </div>
    </div>
  );
};

export default Marquee;
