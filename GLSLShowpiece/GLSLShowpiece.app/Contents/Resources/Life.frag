uniform vec4 pixelDimension;
uniform sampler2D currentGeneration;

varying vec4 lrud;
varying vec3 lry;
varying vec3 xud;

void main()
{
	// read current state of cell
	vec3 currentCell = texture2D(currentGeneration, gl_TexCoord[0].xy).rgb;
	
	// count neighbors
	vec3 neighborCount;
	
	neighborCount  = vec3(greaterThan (texture2D(currentGeneration, lrud.xw).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, lry.xz ).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, lrud.xz).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, xud.xy ).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, lrud.yz).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, lry.yz ).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, lrud.yw).xyz, vec3 (0.0)));
	neighborCount += vec3(greaterThan (texture2D(currentGeneration, xud.xz ).xyz, vec3 (0.0)));

	//if neighborCount == 3, cell gets set to one, else stays same
	currentCell.rgb += vec3(equal(neighborCount, vec3(3))) * vec3(equal(currentCell.rgb, vec3(0)));

	//if neighborCount >= 2, cell stays how it was else it gets zeroed
	currentCell.rgb *= vec3(greaterThanEqual(neighborCount, vec3(2)));
	//if neighborCount <= 3, cell stays how it was else it gets zeroed
	currentCell.rgb *= vec3(lessThanEqual(neighborCount, vec3(3)));

	//Fade the cell
	currentCell.rgb -= vec3(greaterThan(currentCell, vec3(0.2))) * 0.01;

	gl_FragColor = vec4(currentCell.rgb, 1);

}
