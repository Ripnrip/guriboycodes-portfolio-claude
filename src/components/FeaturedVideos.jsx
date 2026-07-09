import React, { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Play, X } from 'lucide-react'

const FeaturedVideos = () => {
  const [selectedVideo, setSelectedVideo] = useState(null)

  const CDN = 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public'

  const videos = [
    {
      id: 1,
      title: 'Elate — AI Wellness Platform',
      event: 'HackZurich 2022 · Finalist',
      url: `${CDN}/videos/hackzurich-2022-elate-720p.mp4`,
      thumbnail: `${CDN}/images/thumbnails/hackzurich-2022-elate.jpg`,
    },
    {
      id: 2,
      title: 'ARon — AI Fitness Coach',
      event: 'HackZurich 2021 · Finalist',
      url: `${CDN}/videos/hackzurich-2021-aron-fitness.mp4`,
      thumbnail: `${CDN}/images/thumbnails/hackzurich-2021-aron.jpg`,
    },
    {
      id: 3,
      title: 'Carly — AR Car Visualizer',
      event: 'HackZurich 2018 · Finalist',
      url: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/videos/hackzurich-carly.mp4',
      thumbnail: `${CDN}/images/thumbnails/hackzurich-2018.jpg`,
    },
    {
      id: 4,
      title: 'London Drone — BBC Documentary',
      event: 'MLH Prime 2017 · 1st Place',
      url: `${CDN}/videos/mlh-2017-drone-bbc.mp4`,
      thumbnail: `${CDN}/images/thumbnails/mlh-2017-drone.jpg`,
    },
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1,
        delayChildren: 0.1,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 50, rotate: 1.5 },
    visible: {
      opacity: 1,
      y: 0,
      rotate: 0,
      transition: { type: 'spring', stiffness: 220, damping: 19 },
    },
  }

  return (
    <section id="videos" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-6xl">
        <motion.h2
          initial={{ opacity: 0, scale: 1.5, rotate: -4 }}
          whileInView={{ opacity: 1, scale: 1, rotate: 0 }}
          viewport={{ once: true, amount: 0.2 }}
          transition={{ type: 'spring', stiffness: 300, damping: 16 }}
          className="mb-12 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-pink px-3 py-1 shadow-brutal">
            Featured Videos
          </span>
        </motion.h2>

        <motion.div
          variants={containerVariants}
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, amount: 0.15 }}
          className="grid gap-8 md:grid-cols-2 lg:grid-cols-3"
        >
          {videos.map((video) => (
            <motion.div
              key={video.id}
              variants={itemVariants}
              className="group cursor-pointer"
              onClick={() => setSelectedVideo(video)}
            >
              <div className="brutal-card brutal-card-hover relative overflow-hidden">
                {/* Thumbnail */}
                <img
                  src={video.thumbnail}
                  alt={video.title}
                  className="h-48 w-full object-cover transition-transform duration-500 group-hover:scale-105"
                />

                {/* Play Button */}
                <div className="absolute inset-0 flex items-center justify-center">
                  <div className="flex h-16 w-16 items-center justify-center border-3 border-ink bg-brutal-orange shadow-brutal transition-transform duration-150 group-hover:scale-110">
                    <Play size={28} className="fill-ink" />
                  </div>
                </div>
              </div>

              {/* Card Info */}
              <div className="mt-4">
                <h3 className="font-display text-lg uppercase leading-tight">{video.title}</h3>
                <p className="mt-1 font-mono text-sm font-bold uppercase">{video.event}</p>
              </div>
            </motion.div>
          ))}
        </motion.div>
      </div>

      {/* Video Modal */}
      <AnimatePresence>
        {selectedVideo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setSelectedVideo(null)}
            className="fixed inset-0 z-50 flex items-center justify-center bg-ink/80 p-4"
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
                onClick={() => setSelectedVideo(null)}
                className="brutal-btn absolute top-4 right-4 z-10 flex h-10 w-10 items-center justify-center bg-brutal-orange"
              >
                <X size={24} />
              </button>

              {/* Video Player */}
              <div className="aspect-video border-b-3 border-ink bg-ink">
                <video
                  src={selectedVideo.url}
                  controls
                  autoPlay
                  className="h-full w-full"
                >
                  Your browser does not support the video tag.
                </video>
              </div>

              {/* Video Info */}
              <div className="p-6">
                <h3 className="mb-2 font-display text-2xl uppercase">{selectedVideo.title}</h3>
                <p className="font-mono text-lg font-bold uppercase">{selectedVideo.event}</p>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  )
}

export default FeaturedVideos
