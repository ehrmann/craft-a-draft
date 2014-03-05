//
//  Shader.fsh
//  CraftADraftPad
//
//  Created by User on 4/29/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
