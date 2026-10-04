# Iteration prompt (sent to the same build agent, identical for every framework)

Next product iteration: implement the change request in `spec/iterations/{FILE}` and look
at its reference PNGs in `spec/iterations/ref/{N}-*.png`. Everything from earlier
iterations must keep working. Same rules as before: change only your directory, use only
your simulator, verify on the simulator with the argent tools, keep `BUILD.md` working
(re-run its Release build commands). Don't ask questions. Reply with a short summary when done.
