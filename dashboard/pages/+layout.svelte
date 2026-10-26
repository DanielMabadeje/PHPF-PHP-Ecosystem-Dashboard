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
	<slot slot="content" />
</EvidenceDefaultLayout>