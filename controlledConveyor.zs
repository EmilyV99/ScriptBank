combodata script controllableConveyor
{
	//Set up the conveyor speed as normal, the script will make it change directions
	//Set the combo to an up-facing conveyor graphic, with 0 flip
	//The graphic will be flipped vertically for down-facing,
	// rotated 90° for right-facing,
	// and flipped horizontally from the right-facing for left-facing
	void run()
	{
		int speed = 2;
		int rate = 3;
		if(this->Flags[1])
		{
			if(this->Attributes[0]) //Horizontal?
			{
				if(this->Attributes[1]) //diagonal?
				{
					speed = Sqrt(Pow(this->Attributes[0],2) + Pow(this->Attributes[1],2));
				}
				else speed = Abs(this->Attributes[0]);
			}
			else if(this->Attributes[1]) //Vertical?
				speed = Abs(this->Attributes[1]);
		}
		this->Flags[1] = true;
		this->Attribytes[0] = rate;
		this->Attributes[0] = 0;
		this->Attributes[1] = 0;
		
		while(true)
		{
			switch(Hero->Dir)
			{
				case DIR_UP:
					this->Attributes[0] = 0;
					this->Attributes[1] = -speed;
					this->Flip = 0;
					break;
				case DIR_DOWN:
					this->Attributes[0] = 0;
					this->Attributes[1] = speed;
					this->Flip = 2;
					break;
				case DIR_LEFT:
					this->Attributes[0] = -speed;
					this->Attributes[1] = 0;
					this->Flip = 5;
					break;
				case DIR_RIGHT:
					this->Attributes[0] = speed;
					this->Attributes[1] = 0;
					this->Flip = 4;
					break;
			}
			int dir = Hero->Dir;
			while(dir == Hero->Dir)
				Waitframe();
		}
	}
}
