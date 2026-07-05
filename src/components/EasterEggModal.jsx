import React from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X } from 'lucide-react'

const EasterEggModal = ({ isOpen, onClose }) => {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="fixed inset-0 z-[100] flex items-center justify-center bg-ink/80 p-4"
        >
          <motion.div
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            exit={{ scale: 0.9, opacity: 0 }}
            onClick={(e) => e.stopPropagation()}
            className="relative w-full max-w-4xl overflow-hidden border-3 border-ink bg-paper shadow-brutal-xl"
          >
            {/* Close Button */}
            <button
              onClick={onClose}
              className="brutal-btn absolute top-4 right-4 z-10 flex h-10 w-10 items-center justify-center bg-brutal-orange"
            >
              <X size={24} />
            </button>

            {/* Fun message */}
            <div className="p-6 text-center">
              <motion.h2
                initial={{ opacity: 0, y: -20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.2 }}
                className="mb-2 font-display text-2xl uppercase"
              >
                You Found the Easter Egg! 🥚
              </motion.h2>
              <motion.p
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.3 }}
                className="mb-6 font-medium"
              >
                Here's a glimpse into working with me...
              </motion.p>
            </div>

            {/* Video Player */}
            <div className="aspect-video border-y-3 border-ink bg-ink">
              <video
                src="https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public/videos/working-with-me.mp4"
                controls
                autoPlay
                className="h-full w-full"
              >
                Your browser does not support the video tag.
              </video>
            </div>

            {/* Footer */}
            <div className="p-6 text-center">
              <p className="font-mono text-sm font-bold uppercase">
                Trigger this again with the Konami Code (↑ ↑ ↓ ↓ ← → ← → B A) or by clicking the profile name 5 times!
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

export default EasterEggModal
