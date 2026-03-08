# Kimi ACP Server Troubleshooting Guide

## Problem Summary

The Kimi CLI agent server configuration in Zed fails with a "Loading" message that appears frozen. The agent never becomes responsive.

## Root Cause

The Kimi CLI's ACP (Agent Communication Protocol) server uses Python's `asyncio` with an epoll/kqueue-based event loop. When run inside Zed's sandboxed environment, the ACP server attempts to register file descriptors with `epoll_ctl`, which triggers a `PermissionError` (Errno 1 - Operation not permitted). This is due to security restrictions (seccomp filters) that prevent certain system calls in the sandbox.

Even when the initial connection succeeds, the asyncio event loop is often left in a broken state, causing the server to hang without sending responses to initialization requests.

## Evidence from Logs

```log
2026-03-07 20:38:00.145 | ERROR | PermissionError: [Errno 1] Operation not permitted
  File ".../selectors.py", line 345, in register
    self._selector.register(key.fd, poller_events)
```

The error occurs when the asyncio event loop tries to monitor stdin for input.

Later logs show successful connection but no response:

```log
2026-03-07 20:39:00.683 | INFO | ACP client connected
2026-03-07 20:39:35.185 | INFO | Read command from stdin: {"jsonrpc":"2.0","id":0,"method":"initialize",...}
2026-03-07 20:39:44.728 | INFO | Session ... has empty context, removing it
```

The server reads the initialize request but never sends a response, causing Zed to show "Loading" indefinitely.

## Related Issues

- **GitHub Issue #1355**: "Failed to initialize ACP session. Error: Internal error: 'list.index(x): x not in list'"
- **GitHub PR #1347**: "skip Kimi auth check for non-kimi providers" (addresses ACP auth issues, still open)

These confirm that the Kimi ACP server has compatibility problems with various editor integrations.

## Why Common Workarounds Fail

1. **PTY allocation via `script` or `unbuffer`**: Doesn't help because the issue is with `epoll_ctl` on the file descriptor, not terminal detection.

2. **I/O forwarding wrappers**: The PermissionError occurs inside the Kimi process itself, not in the wrapper. Forwarding data doesn't change the file descriptor operations Kimi performs.

3. **Using `--print` mode**: This is for direct prompting, not ACP protocol. It doesn't implement the JSON-RPC interface that Zed expects.

## Recommended Solutions

### Option 1: Use OpenRouter (Recommended)

Your configuration already includes OpenRouter with multiple models. Remove the Kimi server and use OpenRouter directly:

```json
"agent_servers": {
  // Remove Kimi CLI entry
}
```

Then select models from your `favorite_models` list in the Zed agent panel.

**Advantages**:
- No compatibility issues
- Fast and reliable
- Supports multiple providers

### Option 2: Use OpenAI-Compatible Endpoint

Configure Kimi's OpenAI-compatible API directly in Zed (if supported by your Zed version):

```json
"agent_servers": {
  "Kimi OpenAI": {
    "type": "openai-compatible",
    "api_key": "sk-JVJYYNr8RiBJHURpFVdE5FB5SwbdOG7MnKHTgNM4boMLGCpC",
    "base_url": "https://api.moonshot.ai/v1"
  }
}
```

This bypasses the Kimi CLI entirely and uses the API directly.

**Note**: You'll need to verify that your Zed version supports `openai-compatible` agent server type.

### Option 3: Use Kimi CLI Externally

Continue using Kimi CLI in a separate terminal window outside of Zed. The interactive mode works perfectly:

```bash
kimi
```

You can still leverage all Kimi features, just not integrated into Zed's agent panel.

### Option 4: Monitor Kimi CLI Updates

The Kimi team is actively working on ACP improvements. To get notified when the issue is fixed:

1. Watch the GitHub repository: https://github.com/moonshotai/kimi-cli
2. Check for releases that mention "ACP" or "Zed" in the changelog
3. Test the configuration again after updates

## Current Configuration Status

The Kimi CLI agent server entry in `settings.json` is currently **commented out** with a warning. It is not active to avoid confusion.

To attempt using it again in the future, you would need to:
1. Ensure Kimi CLI is updated to a version that fixes the ACP sandbox issue
2. Uncomment and potentially adjust the configuration
3. Restart Zed

## Additional Notes

- The Kimi CLI interactive mode (`kimi`) works perfectly fine outside of Zed
- The issue is specific to the `kimi acp` subcommand when run in a sandboxed pipe environment
- Zed's agent system expects a JSON-RPC 2.0 compliant ACP server
- The PermissionError is a Linux kernel security feature (seccomp) that prevents potentially unsafe operations

## References

- Kimi CLI Documentation: https://moonshotai.github.io/kimi-cli/
- Zed Agent Documentation: https://zed.dev/docs/agents
- ACP Protocol: https://github.com/zed-industries/zed/blob/main/crates/agent/src/protocol.rs

---

**Last Updated**: 2026-03-07  
**Kimi CLI Version**: 1.17.0  
**Zed Version**: Latest (as of March 2026)