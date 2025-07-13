#!/usr/bin/env node

const chalk = require("chalk");
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

const mode = process.argv[2] || "watch";
const isBuild = mode === "build";

// Dynamically read workspaces from package.json
const packageJson = JSON.parse(fs.readFileSync("package.json", "utf8"));
const configuredWorkspaces = packageJson.workspaces || [];

// Pattern-based emoji assignment
const getWorkspaceEmojiByPath = (workspacePath) => {
	const lowerPath = workspacePath.toLowerCase();

	// Theme
	if (lowerPath.includes("themes/") || lowerPath.includes("theme"))
		return "🎨";

	// Component libraries
	if (lowerPath.includes("component") || lowerPath.includes("library"))
		return "📦";

	// Plugins (general)
	if (lowerPath.includes("plugins/")) return "🔌";

	// NPM packages
	if (lowerPath.includes("npm_packages/")) return "📦";

	// Default
	return "📋";
};

// Get workspace name from package.json or path
const getWorkspaceNameByPath = (workspacePath) => {
	try {
		const workspacePackageJson = JSON.parse(
			fs.readFileSync(path.join(workspacePath, "package.json"), "utf8"),
		);
		return workspacePackageJson.name || workspacePath.split("/").pop();
	} catch (err) {
		return workspacePath.split("/").pop();
	}
};

// Get emoji by workspace label (for npm-run-all output)
const getWorkspaceEmoji = (workspaceLabel) => {
	return getWorkspaceEmojiByPath(workspaceLabel);
};

// Get name by workspace label (for npm-run-all output)
const getWorkspaceName = (workspaceLabel) => {
	// Try to find the matching configured workspace
	const matchingWorkspace = configuredWorkspaces.find((ws) =>
		workspaceLabel.includes(ws.split("/").pop()),
	);

	if (matchingWorkspace) {
		return getWorkspaceNameByPath(matchingWorkspace);
	}

	// Fallback to label cleanup
	return workspaceLabel.replace(/watch:|theme-json:/, "").trim();
};

// Beautiful startup banner
console.log(
	chalk.bold.blue(`
=================================================================
🚀 ${isBuild ? "Building all workspaces..." : "Starting Development Server"}      
=================================================================
`),
);

// Dynamically generate workspace list with emojis
const getWorkspaceDisplayName = (workspacePath) => {
	// Try to get the actual name from the workspace's package.json
	try {
		const workspacePackageJson = JSON.parse(
			fs.readFileSync(path.join(workspacePath, "package.json"), "utf8"),
		);
		const emoji = getWorkspaceEmojiByPath(workspacePath);
		return `${emoji} ${workspacePackageJson.name}`;
	} catch (err) {
		// Fallback to directory name if no package.json
		const emoji = getWorkspaceEmojiByPath(workspacePath);
		const name = workspacePath.split("/").pop();
		return `${emoji} ${name}`;
	}
};

const workspaces = [...configuredWorkspaces.map(getWorkspaceDisplayName)];

console.log(chalk.cyan("\n📋 Starting the following workspaces:\n"));
workspaces.forEach((workspace, index) => {
	setTimeout(() => {
		process.stdout.write(chalk.green(`  ✓ ${workspace}\n`));
	}, index * 100);
});

// Wait for the list to complete, then start
setTimeout(
	() => {
		console.log(
			chalk.blue(`
=================================================================
🔄 Initializing watch processes...
=================================================================
			`),
		);

		// Use npm-run-all with proper arguments
		const args = [
			"--parallel",
			"--print-label",
			"--print-name",
			"theme-json:watch",
			"watch:*",
		];

		const child = spawn("npm-run-all", args, {
			stdio: ["pipe", "pipe", "pipe"],
			cwd: process.cwd(),
		});

		// Filter output to only show errors, warnings, and minimal status
		let compilationStates = new Map();
		let errorStates = new Map(); // Track error states per workspace
		let isInitialSetup = true;
		let hasShownInitialWatchMessage = false;
		let lastCompilationMessage = new Map(); // To prevent duplicate messages

		const filterOutput = (data) => {
			const output = data.toString();
			const lines = output.split("\n");

			lines.forEach((line) => {
				const lowerLine = line.toLowerCase();

				// Track errors per workspace
				if (
					lowerLine.includes("error") &&
					!lowerLine.includes("compiled")
				) {
					const match = line.match(/\[(.*?)\]/);
					if (match) {
						const workspace = match[1];
						errorStates.set(workspace, true);
					}
					console.log(chalk.red(line));
					return;
				}

				if (lowerLine.includes("warning")) {
					console.log(chalk.yellow(line));
					return;
				}

				// Don't show individual "watching for changes" during initial setup
				if (
					lowerLine.includes("watching") &&
					lowerLine.includes("changes") &&
					isInitialSetup
				) {
					return; // Hide these during initial setup
				}

				// Show compilation start (when files change)
				if (
					!isInitialSetup &&
					(lowerLine.includes("compiling") ||
						lowerLine.includes("rebuilding"))
				) {
					const match = line.match(/\[(.*?)\]/);
					if (match) {
						const workspace = match[1];
						console.log(
							chalk.cyan(
								`🔄 ${getWorkspaceName(workspace)} compiling...`,
							),
						);
					}
					return;
				}

				// Track compilation states for a clean summary
				if (
					lowerLine.includes("webpack") &&
					lowerLine.includes("compiled successfully")
				) {
					const match = line.match(/\[(.*?)\]/);
					if (match) {
						const workspace = match[1];
						const workspaceName = getWorkspaceName(workspace);
						const hasErrors = errorStates.get(workspace);

						// Clear error state when compilation succeeds
						if (hasErrors) {
							errorStates.delete(workspace);
						}

						if (!compilationStates.has(workspace)) {
							// First time compilation (initial setup)
							compilationStates.set(workspace, true);
							if (!hasErrors) {
								console.log(
									chalk.green(`  ✅ ${workspaceName} ready`),
								);
							}

							// Show completion message when ALL workspaces are ready
							if (
								isInitialSetup &&
								!hasShownInitialWatchMessage &&
								compilationStates.size >=
									configuredWorkspaces.length
							) {
								hasShownInitialWatchMessage = true;
								isInitialSetup = false; // Now we're in watch mode immediately
								setTimeout(() => {
									console.log(
										chalk.dim(
											"\n  👁️  Watching for changes...\n",
										),
									);
								}, 1000);
							}
						} else if (
							!isInitialSetup &&
							hasShownInitialWatchMessage
						) {
							// Subsequent compilations (file changes)
							const now = new Date().toLocaleTimeString();
							const lastMessage =
								lastCompilationMessage.get(workspace);
							const currentTime = Date.now();

							// Only show success if we haven't shown a message for this workspace in the last 2 seconds AND there are no errors
							if (
								(!lastMessage ||
									currentTime - lastMessage > 2000) &&
								!hasErrors
							) {
								console.log(
									chalk.green(
										`  ✅ ${workspaceName} compiled successfully at ${now}`,
									),
								);
								console.log(
									chalk.dim(
										"  👁️  Watching for changes...\n",
									),
								);
								lastCompilationMessage.set(
									workspace,
									currentTime,
								);
							}
						}
					}
				}

				// Show build failures
				if (
					lowerLine.includes("failed") ||
					(lowerLine.includes("error") &&
						!lowerLine.includes("compiled"))
				) {
					const match = line.match(/\[(.*?)\]/);
					if (match) {
						const workspace = match[1];
						const workspaceName = getWorkspaceName(workspace);
						const lastMessage =
							lastCompilationMessage.get(workspace);
						const currentTime = Date.now();

						// Only show error message if we haven't shown one for this workspace in the last 2 seconds
						if (!lastMessage || currentTime - lastMessage > 2000) {
							// Show error message after the error details
							setTimeout(() => {
								console.log(
									chalk.red(
										`  ❌ ${workspaceName} compilation failed`,
									),
								);
							}, 100);
							lastCompilationMessage.set(workspace, currentTime);
						}
					}
					console.log(chalk.red(line));
				}
			});
		};

		child.stdout.on("data", filterOutput);
		child.stderr.on("data", (data) => {
			// Always show stdecrr (errors)
			console.log(chalk.red(data.toString()));
		});

		child.on("close", (code) => {
			if (code === 0) {
				console.log(
					chalk.green.bold(`
=================================================================
 🎉 ${isBuild ? "Build Complete!" : "All processes started!"}
=================================================================
			`),
				);
			} else {
				console.log(
					chalk.red.bold(`
=================================================================
❌ Process failed with code ${code}
=================================================================
			`),
				);
				process.exit(code);
			}
		});

		// Handle graceful shutdown for watch mode
		if (!isBuild) {
			process.on("SIGINT", () => {
				console.log(
					chalk.yellow("\n🛑 Shutting down development server..."),
				);
				child.kill();
				console.log(chalk.green("✅ All processes stopped. Goodbye!"));
				process.exit(0);
			});
		}
	},
	workspaces.length * 100 + 500,
);
