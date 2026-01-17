export default function Simulator() {
  return (
    <div className="min-h-screen flex items-center justify-center">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        <h1 className="text-4xl font-bold gradient-text mb-6">
          Protocol Simulator
        </h1>
        <p className="text-gray-400 text-lg">
          Interactive message flow simulator coming soon...
        </p>
        <div className="mt-8 p-6 bg-gray-900 border border-gray-800 rounded-lg">
          <p className="text-sm text-gray-500">
            This page will feature a drag-and-drop interface to simulate message flow
            between T and Z, with adjustable latency and failure modes.
          </p>
        </div>
      </div>
    </div>
  )
}
