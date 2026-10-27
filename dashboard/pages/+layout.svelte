<script>
	import '@evidence-dev/tailwind/fonts.css';
	import '../app.css';
	import { EvidenceDefaultLayout } from '@evidence-dev/core-components';
	export let data;
</script>

<EvidenceDefaultLayout
	{data}
	title="PHP Ecosystem Dashboard"
	githubRepo="https://github.com/DanielMabadeje/PHPF-PHP-Ecosystem-Dashboard"
>
	<div slot="content">
		<slot />
		<footer style="margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #e5e7eb; font-size: 0.85rem; color: #6b7280;">
			Queries and research method by
			<a href="https://github.com/GianfriAur/" target="_blank" rel="noopener">GianfriAur</a>,
			from the PHP Foundation SIG research
			(<a href="https://github.com/ThePHPF/SIG-ambassadors/pull/40" target="_blank" rel="noopener">SIG-ambassadors PR #40</a>).
			Data from <a href="https://httparchive.org" target="_blank" rel="noopener">HTTP Archive</a>.
		</footer>
	</div>
</EvidenceDefaultLayout>