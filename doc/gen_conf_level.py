import xlrd
workbook = xlrd.open_workbook("home_conf.xlsx")
fileOutput = open('Configs.lua','w')
data = "return {\n"
print "There are {} sheets in the workbook".format(workbook.nsheets)
for booksheet in workbook.sheets():
	data = data + "	" + booksheet.name + " = {\n"
	for row in xrange(booksheet.nrows):
		if row != 0:
			data = data + "		[" + str(row) + "]" + " = {"
			for col in xrange(booksheet.ncols):
				key = booksheet.cell(0, col).value
				value = booksheet.cell(row, col).value
				data = data + str(key) + " = " + str(int(value)) + ", "
			data = data[:len(data) - 2]
			data = data + "}, \n"
	data = data + "	},\n"
data = data + "}"
fileOutput.write(data)
fileOutput.close()
