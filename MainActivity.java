package com.example.amulya.listviewcheckboxapp;

import java.util.ArrayList;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.ListView;
import android.widget.TextView;

public class MainActivity extends Activity implements ListViewInterface
{

	Model model;
	ArrayList<Model> fruitsList;
	Listadapter adapter;
	ListView listfruits;
	Button submit;
	TextView text;
	CheckBox checkBox;
	int listcount;
	int countlist=0;

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);

		String fruits[] = { "Apple", "Banana", "Black Berry", "Beetroot",
				"Custard apple", "Dates", "Elderberry", "Endive", "Fennel",
				"Garlic", "Grapes", "Gauvas", "Olive", "Orange", "Papaya Raw",
				"Pear", "Pineapple", "Pomogranate", "Sapodilla", "Watermelon" };

		listfruits = (ListView) findViewById(R.id.list);
		submit = (Button) findViewById(R.id.button1);
		text = (TextView) findViewById(R.id.text1);
		checkBox = (CheckBox) findViewById(R.id.checkbox);

		fruitsList = new ArrayList<Model>();

		for (int i = 0; i < fruits.length; i++) 
		{
			model = new Model();

			model.setName(fruits[i]);

			fruitsList.add(model);
		}

		adapter = new Listadapter(MainActivity.this, fruitsList);

		listfruits.setAdapter(adapter);

		adapter.notifyDataSetChanged();

		
		  
		checkBox.setOnClickListener(new OnClickListener() 
		{
			
			@Override
			public void onClick(View view) 
			{
				// TODO Auto-generated method stub
				boolean checked = ((CheckBox)view).isChecked();
				System.out.println("this is for checking  list items checked is..."+checked+"..."+fruitsList.size());
				if(checked)
				{
					for(int i=0;i<fruitsList.size();i++)
					{
						System.out.println("this is for checking list items checked..."+i);
						fruitsList.get(i).setSelected(true);
					}
					adapter.notifyDataSetChanged();
					
				}
		     
				else
				{
             	for(int i=0;i<fruitsList.size();i++)
					{
						System.out.println("this is for checking list items unchecked..."+i);
						fruitsList.get(i).setSelected(false);
					}
					adapter.notifyDataSetChanged();
					
				}
				
			}	
		});
		
		listcount = listfruits.getCount();
		
		System.out.println("listview count is:"+listcount);
	}

	@Override
	public void checkedStates(int position, boolean val,int total) 
	{
		// TODO Auto-generated method stub
		if(val == false)
		{
			checkBox.setChecked(val);
			fruitsList.get(position).setSelected(val);
			adapter.notifyDataSetChanged();
		}
		else
		{
			fruitsList.get(position).setSelected(val);
			adapter.notifyDataSetChanged();
			
			boolean check = true;
			for(int i = 0;i<total;i++)
			{
				if(fruitsList.get(i).isSelected() == true)
				{
					continue;
				}
				else
				{
					check = false;
					break;
				}
			} 
			System.out.println("this is for checking list items in interface "+check);
			if(check == false)
			{
				checkBox.setChecked(false);
			}
			else
			{
				checkBox.setChecked(true);
			}
		}
	}
	
	}

