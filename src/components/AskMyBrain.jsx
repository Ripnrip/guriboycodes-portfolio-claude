import React, { useState, useRef, useEffect } from 'react'
import { motion } from 'framer-motion'
import { Brain, Send } from 'lucide-react'

// Tiny client-side knowledge base — first entry whose keyword matches wins
const KNOWLEDGE = [
  {
    keys: ['paypal', 'venmo', 'work', 'job', 'staff', 'mercury', 'agent0'],
    answer:
      "Gurinder is a Staff Software Engineer at PayPal (2020–present). Highlights: Agent0 (autonomous AI agent framework for Venmo & PayPal teams), Project Mercury (agentic e-commerce with GraphRAG/MCP, built in 72 hrs and presented to the SVP of AI), the $400M Amex partnership, the $60M CVS contract, and a QRC Widget patent — 90M+ users impacted.",
  },
  {
    keys: ['hackathon', 'zurich', 'mlh', 'win', 'bbc', 'drone'],
    answer:
      '28+ hackathons across 6+ countries with 2 first-place wins. Standouts: MLH Prime 2017 (1st place, London drone project featured in a BBC documentary) and three HackZurich finalist runs — Elate (2022), ARon (2021), and Carly (2018).',
  },
  {
    keys: ['ai', 'ml', 'rag', 'llm', 'mcp', 'graphrag', 'agent', 'model'],
    answer:
      'His AI/ML stack: CoreML and MLX on-device, RAG systems with ChromaDB and vector DBs, multi-agent orchestration, GraphRAG, and MCP. He builds agentic systems at PayPal and ships AI side projects constantly.',
  },
  {
    keys: ['ios', 'swift', 'mobile', 'app', 'arkit'],
    answer:
      'iOS is home turf: Swift, SwiftUI, Objective-C, ARKit, Core Bluetooth, Dynamic Island/Live Activities — plus Flutter and React Native. Previously built for Google Stadia and Morgan Stanley Wealth Management.',
  },
  {
    keys: ['mentor', 'interview', 'community', 'erg', 'teach', 'student', 'lead'],
    answer:
      '500+ technical interviews conducted, 20+ engineers mentored, Sikh Faith ERG Co-Lead at PayPal (150+ members), CTE Advisory Board member, and coding workshops for underrepresented youth.',
  },
  {
    keys: ['patent', 'qrc'],
    answer:
      'He holds a patent for the QRC Widget at PayPal, which cut checkout friction by 66%.',
  },
  {
    keys: ['project', 'built', 'portfolio', 'side'],
    answer:
      '20 projects in the grid above — AI/ML (Agentic-SEO, Flow, Zai Vision Suite), creative (Ethereal Dimension, Cycles of Fate), mobile AR (ARon, Carly), and community/education tools. Hit the category filters in the Projects section.',
  },
  {
    keys: ['contact', 'email', 'hire', 'reach', 'linkedin', 'collab'],
    answer:
      "Email contact@guriboycodes.com, or find him on GitHub (@Ripnrip) and LinkedIn. He's always up for building something legendary.",
  },
  {
    keys: ['easter', 'egg', 'konami', 'secret', 'hidden'],
    answer:
      'Try the Konami code (↑ ↑ ↓ ↓ ← → ← → B A) — or click the "G" logo 5 times. 🥚',
  },
]

const FALLBACK =
  "My brain indexes PayPal work, hackathons, the AI/ML + iOS stack, mentorship, patents, projects, and contact info. Try one of those — or try the chips below."

const SUGGESTIONS = [
  'What does he do at PayPal?',
  'Biggest hackathon win?',
  "What's his AI stack?",
  'Any easter eggs?',
]

const answerFor = (question) => {
  const q = question.toLowerCase()
  const hit = KNOWLEDGE.find((entry) => entry.keys.some((k) => q.includes(k)))
  return hit ? hit.answer : FALLBACK
}

const AskMyBrain = () => {
  const [messages, setMessages] = useState([
    { role: 'bot', text: "Hi! I'm Gurinder's brain (well, a lookup table of it). Ask me about his work, hackathons, or stack." },
  ])
  const [input, setInput] = useState('')
  const scrollRef = useRef(null)

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight
    }
  }, [messages])

  const ask = (question) => {
    const q = question.trim()
    if (!q) return
    setMessages((prev) => [...prev, { role: 'user', text: q }])
    setInput('')
    setTimeout(() => {
      setMessages((prev) => [...prev, { role: 'bot', text: answerFor(q) }])
    }, 450)
  }

  return (
    <section id="brain" className="px-4 py-20 sm:px-6 lg:px-8">
      <div className="mx-auto max-w-3xl">
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="mb-4 text-center font-display text-3xl uppercase tracking-tight sm:text-4xl"
        >
          <span className="inline-block bg-brutal-mint px-3 py-1 shadow-brutal">
            Ask My Brain
          </span>
        </motion.h2>

        <motion.p
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="mb-8 text-center font-mono text-sm font-bold uppercase tracking-wide"
        >
          Zero-API chatbot · runs entirely in your browser
        </motion.p>

        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="brutal-card shadow-brutal-lg"
        >
          {/* Terminal-style header */}
          <div className="flex items-center gap-3 border-b-3 border-ink bg-ink px-4 py-3">
            <Brain size={20} className="text-brutal-yellow" />
            <span className="font-mono text-sm font-bold uppercase tracking-widest text-paper">
              brain.exe — online
            </span>
            <span className="ml-auto flex gap-2">
              <span className="h-3 w-3 border-2 border-paper bg-brutal-orange" />
              <span className="h-3 w-3 border-2 border-paper bg-brutal-yellow" />
              <span className="h-3 w-3 border-2 border-paper bg-brutal-mint" />
            </span>
          </div>

          {/* Messages */}
          <div ref={scrollRef} className="h-80 space-y-4 overflow-y-auto bg-paper p-4">
            {messages.map((msg, i) => (
              <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div
                  className={`max-w-[85%] border-3 border-ink p-3 text-sm font-medium shadow-brutal-sm ${
                    msg.role === 'user' ? 'bg-brutal-yellow' : 'bg-white'
                  }`}
                >
                  <p className="mb-1 font-mono text-[10px] font-bold uppercase tracking-widest">
                    {msg.role === 'user' ? 'You' : 'Brain'}
                  </p>
                  {msg.text}
                </div>
              </div>
            ))}
          </div>

          {/* Suggestion chips */}
          <div className="flex flex-wrap gap-2 border-t-3 border-ink bg-white p-3">
            {SUGGESTIONS.map((s) => (
              <button key={s} onClick={() => ask(s)} className="brutal-chip hover:bg-brutal-lilac">
                {s}
              </button>
            ))}
          </div>

          {/* Input */}
          <form
            onSubmit={(e) => {
              e.preventDefault()
              ask(input)
            }}
            className="flex border-t-3 border-ink"
          >
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              placeholder="ASK SOMETHING..."
              className="min-w-0 flex-1 bg-white px-4 py-3 font-mono text-sm font-bold uppercase placeholder:text-ink/40 focus:bg-brutal-yellow/20 focus:outline-none"
            />
            <button
              type="submit"
              className="flex items-center gap-2 border-l-3 border-ink bg-brutal-orange px-6 py-3 font-bold uppercase transition-colors hover:bg-brutal-yellow"
            >
              <Send size={16} />
              Ask
            </button>
          </form>
        </motion.div>
      </div>
    </section>
  )
}

export default AskMyBrain
