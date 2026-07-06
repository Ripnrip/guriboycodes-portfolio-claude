import React, { useState } from 'react'
import { Menu, X } from 'lucide-react'
import { motion } from 'framer-motion'
import useEasterEgg from '../hooks/useEasterEgg'
import EasterEggModal from './EasterEggModal'

const Navigation = () => {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
  const [easterEggOpen, setEasterEggOpen] = useState(false)
  const { handleProfileClick } = useEasterEgg(() => setEasterEggOpen(true))

  const navLinks = [
    { label: 'About', href: '#about' },
    { label: 'Skills', href: '#skills' },
    { label: 'Graph', href: '#graph' },
    { label: 'Projects', href: '#projects' },
    { label: 'Hackathons', href: '#hackathons' },
    { label: 'Videos', href: '#videos' },
    { label: 'Leadership', href: '#leadership' },
    { label: 'Brain', href: '#brain' },
    { label: 'Contact', href: '#contact' },
  ]

  return (
    <nav className="fixed top-0 z-50 w-full border-b-3 border-ink bg-paper">
      <div className="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
        <div className="flex h-16 items-center justify-between">
          {/* Logo */}
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ duration: 0.4 }}
            className="flex cursor-pointer items-center gap-3"
            onClick={() => {
              handleProfileClick()
              window.scrollTo({ top: 0, behavior: 'smooth' })
            }}
          >
            <div className="flex h-9 w-9 items-center justify-center border-3 border-ink bg-brutal-orange font-display text-lg shadow-brutal-sm">
              G
            </div>
            <span className="hidden font-display text-lg uppercase tracking-tight sm:inline">
              GuriboyCodes
            </span>
          </motion.div>

          {/* Desktop Nav Links */}
          <div className="hidden items-center gap-1 md:flex">
            {navLinks.map((link, i) => (
              <motion.a
                key={link.label}
                href={link.href}
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.3, delay: i * 0.05 }}
                className="border-2 border-transparent px-3 py-1.5 font-mono text-xs font-bold uppercase tracking-wide transition-colors hover:border-ink hover:bg-brutal-yellow"
              >
                {link.label}
              </motion.a>
            ))}
          </div>

          {/* Mobile Menu Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="brutal-btn bg-white p-2 md:hidden"
            aria-label="Toggle mobile menu"
          >
            {mobileMenuOpen ? <X size={20} /> : <Menu size={20} />}
          </button>
        </div>

        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: 'auto' }}
            exit={{ opacity: 0, height: 0 }}
            className="border-t-3 border-ink py-4 md:hidden"
          >
            <div className="space-y-2">
              {navLinks.map((link) => (
                <a
                  key={link.label}
                  href={link.href}
                  className="block border-2 border-ink bg-white px-4 py-2 font-mono text-sm font-bold uppercase transition-colors hover:bg-brutal-yellow"
                  onClick={() => setMobileMenuOpen(false)}
                >
                  {link.label}
                </a>
              ))}
            </div>
          </motion.div>
        )}
      </div>

      {/* Easter Egg Modal */}
      <EasterEggModal isOpen={easterEggOpen} onClose={() => setEasterEggOpen(false)} />
    </nav>
  )
}

export default Navigation
