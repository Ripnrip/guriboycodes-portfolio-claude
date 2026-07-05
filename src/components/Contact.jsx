import React from 'react'
import { motion } from 'framer-motion'
import { Github, Linkedin, Mail, ExternalLink } from 'lucide-react'

const Contact = () => {
  const socialLinks = [
    { icon: Github, href: 'https://github.com/Ripnrip', label: 'GitHub', bg: 'bg-brutal-yellow' },
    { icon: Linkedin, href: 'https://www.linkedin.com/in/gurinder-singh-a30a1a48', label: 'LinkedIn', bg: 'bg-brutal-lilac' },
    { icon: Mail, href: 'mailto:contact@guriboycodes.com', label: 'Email', bg: 'bg-brutal-mint' },
  ]

  return (
    <section id="contact" className="border-t-3 border-ink px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-4xl text-center">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-6 font-display text-4xl uppercase tracking-tight sm:text-5xl"
        >
          <span className="inline-block bg-brutal-orange px-3 py-1 shadow-brutal">
            Let's Connect
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="mx-auto mb-12 max-w-2xl text-lg font-medium"
        >
          Interested in collaborating on innovative projects? Get in touch and let's build something legendary together.
        </motion.p>

        {/* Social Links */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="mb-16 flex justify-center gap-6"
        >
          {socialLinks.map((link) => {
            const Icon = link.icon
            return (
              <a
                key={link.label}
                href={link.href}
                target="_blank"
                rel="noopener noreferrer"
                className={`brutal-btn ${link.bg} p-4`}
                aria-label={link.label}
              >
                <Icon size={24} />
              </a>
            )
          })}
        </motion.div>

        {/* CTA Button */}
        <motion.a
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          href="mailto:contact@guriboycodes.com"
          className="brutal-btn group inline-flex items-center gap-2 bg-ink px-8 py-4 text-lg text-paper"
        >
          <span>Send me an email</span>
          <ExternalLink size={18} className="transition-transform group-hover:translate-x-1" />
        </motion.a>

        {/* Footer */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="mt-20 border-t-3 border-ink pt-12 text-center"
        >
          <p className="mb-4 font-mono text-sm font-bold uppercase">
            Built with <span className="bg-brutal-orange px-1">Claude</span> — AI-powered development
          </p>
          <p className="font-mono text-xs">
            © {new Date().getFullYear()} GuriboyCodes. All rights reserved.
          </p>
          <div className="mt-6 flex items-center justify-center gap-2 font-mono text-xs font-bold uppercase">
            <span>Powered by</span>
            <a
              href="https://claude.ai"
              target="_blank"
              rel="noopener noreferrer"
              className="underline decoration-2 underline-offset-2 hover:bg-brutal-yellow"
            >
              Claude AI
            </a>
            <span>•</span>
            <a
              href="https://vitejs.dev"
              target="_blank"
              rel="noopener noreferrer"
              className="underline decoration-2 underline-offset-2 hover:bg-brutal-yellow"
            >
              Vite
            </a>
            <span>•</span>
            <a
              href="https://tailwindcss.com"
              target="_blank"
              rel="noopener noreferrer"
              className="underline decoration-2 underline-offset-2 hover:bg-brutal-yellow"
            >
              Tailwind CSS
            </a>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default Contact
