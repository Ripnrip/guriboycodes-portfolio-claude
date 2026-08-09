import React from 'react'
import { motion } from 'framer-motion'
import { Github, Linkedin, Mail, Download, ArrowRight } from 'lucide-react'
import { KineticWords, staggerParent, slamUp, SPRING } from '../utils/motion'

const Hero = () => {
  const socialLinks = [
    { icon: Github, href: 'https://github.com/Ripnrip', label: 'GitHub' },
    { icon: Linkedin, href: 'https://www.linkedin.com/in/gurinder-singh-a30a1a48', label: 'LinkedIn' },
    { icon: Mail, href: 'mailto:gurinder@binary-bros.com', label: 'Email' },
  ]

  return (
    <section id="about" className="flex min-h-screen items-center justify-center px-4 pt-24 pb-16 sm:px-6 lg:px-8">
      <div className="mx-auto w-full max-w-6xl">
        <div className="grid items-center gap-12 md:grid-cols-2">
          {/* Left Content */}
          <div className="space-y-8">
            <motion.p
              initial={{ opacity: 0, scale: 1.4, rotate: -6 }}
              animate={{ opacity: 1, scale: 1, rotate: 0 }}
              transition={{ type: 'spring', stiffness: 300, damping: 14, delay: 0.1 }}
              className="inline-block border-2 border-ink bg-brutal-yellow px-3 py-1 font-mono text-xs font-bold uppercase tracking-widest shadow-brutal-sm"
            >
              Staff iOS & AI/ML Engineer @ PayPal
            </motion.p>

            {/* Kinetic headline: each line's words slam up out of a clipped box */}
            <h1 className="font-display text-4xl uppercase leading-none tracking-tight sm:text-5xl lg:text-6xl">
              <KineticWords text="Building" delay={0.25} />
              <br />
              <KineticWords text="Legendary Apps" delay={0.4} />
              <br />
              <span className="mt-2 inline-block overflow-hidden">
                <motion.span
                  initial={{ y: '110%' }}
                  animate={{ y: '0%' }}
                  transition={{ ...SPRING, delay: 0.65 }}
                  className="inline-block bg-brutal-orange px-2 shadow-brutal"
                >
                  at the edge of
                </motion.span>
              </span>
              <br />
              <span className="mt-2 inline-block overflow-hidden">
                <motion.span
                  initial={{ y: '110%' }}
                  animate={{ y: '0%' }}
                  transition={{ ...SPRING, delay: 0.8 }}
                  className="inline-block bg-ink px-2 text-paper shadow-brutal"
                >
                  iOS & AI
                </motion.span>
              </span>
            </h1>

            <motion.p
              initial={{ opacity: 0, x: -30 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ ...SPRING, delay: 1 }}
              className="max-w-xl border-l-3 border-ink pl-4 text-lg font-medium"
            >
              Crafting scalable solutions used by 90M+ people. Shipping fast, mentoring forward, hacking everything.
            </motion.p>

            {/* CTA Buttons */}
            <motion.div
              initial="hidden"
              animate="visible"
              variants={staggerParent(0.12, 1.15)}
              className="flex flex-wrap gap-4"
            >
              <motion.a
                variants={slamUp}
                href="#projects"
                className="brutal-btn group flex items-center gap-2 bg-ink px-6 py-3 text-paper"
              >
                <span>View Projects</span>
                <ArrowRight size={18} className="transition-transform group-hover:translate-x-1" />
              </motion.a>
              <motion.a
                variants={slamUp}
                href="#contact"
                className="brutal-btn flex items-center gap-2 bg-white px-6 py-3"
              >
                <Download size={18} />
                <span>Resume</span>
              </motion.a>
            </motion.div>

            {/* Social Links */}
            <motion.div
              initial="hidden"
              animate="visible"
              variants={staggerParent(0.1, 1.35)}
              className="flex gap-3"
            >
              {socialLinks.map((link) => {
                const Icon = link.icon
                return (
                  <motion.a
                    key={link.label}
                    variants={slamUp}
                    href={link.href}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="brutal-btn bg-brutal-lilac p-3"
                    aria-label={link.label}
                  >
                    <Icon size={20} />
                  </motion.a>
                )
              })}
            </motion.div>
          </div>

          {/* Right Image */}
          <motion.div
            initial={{ opacity: 0, scale: 0.85, rotate: 3 }}
            animate={{ opacity: 1, scale: 1, rotate: 0 }}
            transition={{ type: 'spring', stiffness: 200, damping: 18, delay: 0.5 }}
            className="flex justify-center"
          >
            <div className="relative">
              {/* Offset color block slides out behind the photo */}
              <motion.div
                initial={{ x: 0, y: 0 }}
                animate={{ x: 0, y: 0 }}
                className="absolute -right-4 -bottom-4 h-full w-full border-3 border-ink bg-brutal-yellow"
              />
              <div className="relative h-64 w-64 overflow-hidden border-3 border-ink bg-white sm:h-80 sm:w-80">
                <img
                  src="https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/images/profile/gurinder.jpg"
                  alt="Gurinder Singh — GuriboyCodes"
                  className="h-full w-full object-cover"
                  loading="lazy"
                />
              </div>
              {/* Sticker badge pops in, then idles with a slow wobble */}
              <motion.div
                initial={{ opacity: 0, scale: 0, rotate: -30 }}
                animate={{ opacity: 1, scale: 1, rotate: [-30, -6, -8, -4, -6] }}
                transition={{
                  opacity: { delay: 1.1, duration: 0.2 },
                  scale: { type: 'spring', stiffness: 320, damping: 12, delay: 1.1 },
                  rotate: { delay: 1.1, duration: 5, repeat: Infinity, repeatType: 'mirror', ease: 'easeInOut' },
                }}
                className="absolute -top-5 -left-6 border-3 border-ink bg-brutal-orange px-3 py-1.5 font-display text-sm uppercase shadow-brutal"
              >
                28+ Hackathons
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  )
}

export default Hero
