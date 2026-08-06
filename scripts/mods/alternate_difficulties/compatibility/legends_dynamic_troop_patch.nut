if (!("Compatibility" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Compatibility <- {};
}

::AlternateDifficulties.Compatibility.DynamicTroops <- {
	function register()
	{
		::Const.World.Common.dynamicSelectTroop <- function (_list, _resources, _scale, _map, _credits)
		{
			local candidates = [];
			local T = [];
			local totalWeight = 0;
			//Go through each Item in the spawn list (which are structures defining enemies)
			foreach (t in _list)
			{
				// foreach (k,v in t) {
				//  	this.logInfo("K " + k + ": " +v)
				// }
				//Don't pick if resources are greater than threshold
				if ("MaxR" in t && _resources > t.MaxR)
				{
					continue;
				}
		
				//Don't pick if resources are less than threshold AND we have not surpassed
				//the given days in game based on Difficulty
				if ("MinR" in t)
				{
					local minr = 0;
					if (typeof(t.MinR) == "function")
					{
						minr = t.MinR()
					}
					else
					{
						minr = t.MinR;
					}
		
					if (_resources < minr)
					{
						::AlternateDifficulties.Mod.Debug.printLog("[AlternateDifficulties][DynamicTroops] excluded MinR troop minR=" + minr + " resources=" + _resources);
						continue;
					}
				}
		
				local w = 0;
				if (typeof(t.Weight) == "function")
				{
					w = t.Weight(_scale)
				}
				else
				{
					w = t.Weight;
				}
		
				if (w == 0)
				{
					T.push(t);
					continue;
				}
				totalWeight += w;
				candidates.push(t);
			}
		
			local r = this.Math.rand(1, totalWeight);
			foreach (t in candidates)
			{
				local w = 0;
				if (typeof(t.Weight) == "function")
				{
					w = t.Weight(_scale);
				}
				else
				{
					w = t.Weight;
				}
				r = r - w;
				if (r > 0)
				{
					continue;
				}
				T.push(t);
				break;
			}
		
			foreach (troop in T)
			{
				if ("Type" in troop)
				{
		
					local key = troop.Type.Script;
					if (!(key in _map))
					{
						_map[key] <- {
							Type = troop.Type,
							Num = 0
						}
					}
		
					if ("Roll" in troop)
					{
						if (typeof(troop.Roll) == "function")
						{
							if (!troop.Roll(_map[key].Num))
							{
								continue;
							}
						}
						else
						{
							local chance = 1.0 / (1.0 + this.Math.pow(_map[key].Num, 0.5)) * 100;
							if (this.Math.rand(1, 100) > chance)
							{
								continue;
							}
						}
					}
		
					_credits -= troop.Cost;
					_map[key].Num += 1;
		
		
					if ("MaxCount" in troop)
					{
						for (local i = 1; i < troop.MaxCount; i = ++i)
						{
							if (_credits < 0)
							{
								break;
							}
		
							local w = 100;
							if (typeof(troop.Weight) == "function")
							{
								w = troop.Weight(_scale);
							}
							else
							{
								w = troop.Weight;
							}
		
							if (this.Math.rand(0, 100) < w)
							{
								_credits -= troop.Cost;
								local key = troop.Type.Script;
								if (!(key in _map))
								{
									_map[key] <- {
										Type = troop.Type,
										Num = 0
									}
								}
								_map[key].Num += 1;
							}
						}
					}
		
				}
		
		
				if ("Guards" in troop)
				{
					local maxCount = "MaxGuards" in troop ? troop.MaxGuards : 1;
					local minCount = "MinGuards" in troop ? troop.MinGuards : 1;
					for (local i = 0; i < maxCount; i = ++i)
					{
						local weight = 100;
						if ("MaxGuardsWeight" in troop)
						{
							weight = troop.MaxGuardsWeight;
						}
						local r = this.Math.rand(0, 100);
						if (weight < r && i >= minCount)
						{
							continue;
						}
		
						_credits = this.Const.World.Common.dynamicSelectTroop(troop.Guards, _resources, _scale, _map, _credits);
		
						if (_credits < 0)
						{
							break;
						}
					}
				}
		
				if (_credits < 0)
				{
					return _credits;
				}
		
				if (!("SortedTypes" in troop))
				{
					continue;
				}
		
				local points = troop.SortedTypes[0].Cost;
				if (troop.SortedTypes.len() > 1)
				{
					local meanScaled = troop.MinMean + _scale * (troop.MaxMean - troop.MinMean);
					points = this.Math.max(points, this.Const.LegendMod.BoxMuller.BoxMuller(meanScaled, troop.Deviation));
					//this.logInfo(cat + " Mean " + meanScaled + " : Deviation " + troops.Deviation + " : Points " + points)
				}
		
				//Always purchase the most expensive unit we can
				for (local i = troop.SortedTypes.len() - 1; i >= 0; i = --i)
				{
					if (troop.SortedTypes[i].Cost > points)
					{
						continue;
					}
		
					local index = this.Math.rand(0, troop.SortedTypes[i].Types.len() - 1);
		
					if ("MaxR" in troop.SortedTypes[i].Types[index] && _resources > troop.SortedTypes[i].Types[index].MaxR)
					{
						continue;
					}
		
					if ("MinR" in  troop.SortedTypes[i].Types[index])
					{
						local minr = 0;
						if (typeof(troop.SortedTypes[i].Types[index].MinR) == "function")
						{
							minr = troop.SortedTypes[i].Types[index].MinR()
						}
						else
						{
							minr = troop.SortedTypes[i].Types[index].MinR;
						}
		
						if (_resources < minr)
					{
						::AlternateDifficulties.Mod.Debug.printLog("[AlternateDifficulties][DynamicTroops] excluded MinR troop minR=" + minr + " resources=" + _resources);
						continue;
					}
					}
		
					local key = troop.SortedTypes[i].Types[index].Type.Script;
					if (!(key in _map))
					{
						_map[key] <- {
							Type = troop.SortedTypes[i].Types[index].Type,
							Num = 0
						}
					}
		
					if ("Roll" in troop)
					{
						if (typeof(troop.Roll) == "function")
						{
							if (!troop.Roll(_map[key].Num))
							{
								continue;
							}
						}
						else
						{
							local chance = 1.0 / (1.0 + this.Math.pow(_map[key].Num, 0.5)) * 100;
							if (this.Math.rand(1, 100) > chance)
							{
								continue;
							}
						}
					} else if ("Roll" in troop.SortedTypes[i].Types[index]) {
						if (typeof(troop.SortedTypes[i].Types[index].Roll) == "function")
						{
							if (!troop.SortedTypes[i].Types[index].Roll(_map[key].Num))
							{
								continue;
							}
						}
						else
						{
							local chance = 1.0 / (1.0 + this.Math.pow(_map[key].Num, 0.5)) * 100;
							if (this.Math.rand(1, 100) > chance)
							{
								continue;
							}
						}
					}
		
		
		
					_credits -= troop.SortedTypes[i].Types[index].Cost;
					_map[key].Num += 1;
		
					if ("Guards" in troop.SortedTypes[i].Types[index])
					{
						_credits = this.Const.World.Common.dynamicSelectTroop(troop.SortedTypes[i].Types[index].Guards, _resources, _scale, _map, _credits)
					}
					break;
				}
			}
		//	if (startingCredits == _credits && T.len() > 0) {
		//		throw "dynamicSelectTroop didn't change credits"
		//	}
			return _credits
		}
		
	}
};

