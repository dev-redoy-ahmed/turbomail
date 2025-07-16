// TurboMail Admin Panel JavaScript
document.addEventListener('DOMContentLoaded', function() {
    // Add loading animation to forms
    const forms = document.querySelectorAll('form');
    forms.forEach(form => {
        form.addEventListener('submit', function() {
            const submitBtn = form.querySelector('button[type="submit"]');
            if (submitBtn) {
                submitBtn.innerHTML = '<span class="loading"></span> Processing...';
                submitBtn.disabled = true;
            }
        });
    });

    // Add confirmation for delete actions
    const deleteButtons = document.querySelectorAll('.btn-danger');
    deleteButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            if (!confirm('Are you sure you want to delete this item?')) {
                e.preventDefault();
            }
        });
    });

    // Auto-hide alerts after 5 seconds
    const alerts = document.querySelectorAll('.alert');
    alerts.forEach(alert => {
        setTimeout(() => {
            alert.style.opacity = '0';
            setTimeout(() => {
                alert.remove();
            }, 300);
        }, 5000);
    });

    // Add glow effect to cards on hover
    const cards = document.querySelectorAll('.card');
    cards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.classList.add('glow');
        });
        card.addEventListener('mouseleave', function() {
            this.classList.remove('glow');
        });
    });

    // Real-time system status check (mock)
    function updateSystemStatus() {
        const statusElements = document.querySelectorAll('.status');
        statusElements.forEach(status => {
            // Simulate random status updates
            const isOnline = Math.random() > 0.1; // 90% chance of being online
            status.className = `status ${isOnline ? 'online' : 'offline'}`;
            status.textContent = isOnline ? 'Online' : 'Offline';
        });
    }

    // Update status every 30 seconds
    setInterval(updateSystemStatus, 30000);

    // Copy to clipboard functionality
    function copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(function() {
            // Show temporary success message
            const toast = document.createElement('div');
            toast.className = 'alert alert-success';
            toast.style.position = 'fixed';
            toast.style.top = '20px';
            toast.style.right = '20px';
            toast.style.zIndex = '9999';
            toast.textContent = 'Copied to clipboard!';
            document.body.appendChild(toast);
            
            setTimeout(() => {
                toast.remove();
            }, 2000);
        });
    }

    // Add copy buttons to code blocks
    const codeBlocks = document.querySelectorAll('.code-block');
    codeBlocks.forEach(block => {
        const copyBtn = document.createElement('button');
        copyBtn.className = 'btn btn-secondary';
        copyBtn.style.position = 'absolute';
        copyBtn.style.top = '10px';
        copyBtn.style.right = '10px';
        copyBtn.style.fontSize = '12px';
        copyBtn.style.padding = '5px 10px';
        copyBtn.textContent = 'Copy';
        
        block.style.position = 'relative';
        block.appendChild(copyBtn);
        
        copyBtn.addEventListener('click', () => {
            copyToClipboard(block.textContent.replace('Copy', '').trim());
        });
    });
});